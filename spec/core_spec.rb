require 'spec_helper'

describe ZoneRanger::Core do

  def timeize t_or_s
    t_or_s.is_a?(Time) ? t_or_s : Time.parse(t_or_s)
  end

  def validate_active zr, time
    Timecop.freeze(timeize(time))
    zr.includes?(timeize(time)).should(be_true, "#{time.to_s} expected ACTIVE")
    Timecop.return
  end

  def validate_inactive zr, time
    Timecop.freeze(timeize(time))
    zr.includes?(timeize(time)).should(be_false, "#{time.to_s} expected INACTIVE")
    Timecop.return
  end

  describe "standard operation" do
    it "should require a start time, duration, and timezone" do
      expect{ ZoneRanger::Core.new.includes? Time.now, 30 }.to raise_error ArgumentError
      expect{ ZoneRanger::Core.new.includes? Time.now }.to raise_error ArgumentError
    end

    it "should not throw error if all fields are supplied" do
      ZoneRanger::Core.new("#{Time.now - 300}", 30, "Eastern Time (US & Canada)").includes?
    end

    it "should accept a Time parameter" do
      ZoneRanger::Core.new("#{Time.now - 300}", 30, "Eastern Time (US & Canada)").includes? Time.now.utc
    end

    it "should repeat? if told" do
      zr = ZoneRanger::Core.new('2013-04-01 06:00 -04:00', 30, "Eastern Time (US & Canada)", :repeat => :daily)
      zr.repeat?.should be_true
    end

    it "should have a timezone" do
      zr = ZoneRanger::Core.new('2013-04-01 06:00 -04:00', 30, "Eastern Time (US & Canada)")
      zr.timezone_object.should be_a ActiveSupport::TimeZone
    end
  end

  describe "#time_range" do
    context "no repeat" do
      it "should return the correct time range - same day" do
        zr = ZoneRanger::Core.new('2013-04-01 06:00 -04:00', 30, "Eastern Time (US & Canada)")
        zr.time_range.should eql([Time.parse('2013-04-01 06:00 -04:00'), Time.parse('2013-04-01 06:30 -04:00')])
      end

      it "should return the correct time range - crossing midnight in user's timezone" do
        zr = ZoneRanger::Core.new('2013-04-01 23:01 -04:00', 60, "Eastern Time (US & Canada)")
        zr.time_range.should eql([Time.parse('2013-04-01 23:01 -04:00'), Time.parse('2013-04-02 00:01 -04:00')])
      end

      it "should work with other time zones" do
        zr = ZoneRanger::Core.new('2013-04-01 23:01 -07:00', 60, "Pacific Time (US & Canada)")
        zr.time_range.should eql([Time.parse('2013-04-01 23:01 -07:00'), Time.parse('2013-04-02 00:01 -07:00')])
      end
    end

    context "repeat daily" do
      it "should return the correct time range - same day" do
        zr = ZoneRanger::Core.new('2013-04-01 06:00 -04:00', 30, "Eastern Time (US & Canada)", :repeat => :daily)
        zr.time_range(Time.parse('2013-04-02 06:00 -04:00')).should eql([Time.parse('2013-04-02 06:00 -04:00'), Time.parse('2013-04-02 06:30 -04:00')])
      end

      it "should return the correct time range - crossing midnight in user's timezone" do
        zr = ZoneRanger::Core.new('2013-04-01 23:01 -04:00', 60, "Eastern Time (US & Canada)", :repeat => :daily)
        zr.time_range(Time.parse('2013-04-02 06:00 -04:00')).should eql([Time.parse('2013-04-02 23:01 -04:00'), Time.parse('2013-04-03 00:01 -04:00')])
      end

      it "should work with other time zones" do
        zr = ZoneRanger::Core.new('2013-04-01 23:01 -07:00', 60, "Pacific Time (US & Canada)", :repeat => :daily)
        zr.time_range(Time.parse('2013-04-02 06:00 -07:00')).should eql([Time.parse('2013-04-02 23:01 -07:00'), Time.parse('2013-04-03 00:01 -07:00')])
      end
    end
  end

  describe "#expired?" do

    let(:zr_daily) { ZoneRanger::Core.new('2013-04-01 23:01 -04:00', 60, "Eastern Time (US & Canada)", :repeat => :daily, :ending => '2013-06-01')}
    let(:zr_weekly) { ZoneRanger::Core.new('2013-04-01 00:01:00 -07:00', 60, "Pacific Time (US & Canada)", :ending => '2013-06-01', :repeat => :weekly)}
    let(:zr_monthly_by_day_of_month) { ZoneRanger::Core.new('2013-04-01 00:01:00 -07:00', 60, "Pacific Time (US & Canada)", :ending => '2013-06-01', :repeat => :monthly_by_day_of_month)}
    let(:zr_monthly_by_day_of_week) { ZoneRanger::Core.new('2013-04-01 00:01:00 -07:00', 60, "Pacific Time (US & Canada)", :ending => '2013-06-01', :repeat => :monthly_by_day_of_week)}

    it "should return true if the checked time is past the expired time" do
      [zr_daily, zr_weekly, zr_monthly_by_day_of_month, zr_monthly_by_day_of_week].each do |zr|
        zr.expired?(Time.parse('2013-06-02 00:00:00 -07:00')).should(be_true, "#{zr.repeat_type} expected EXPIRED")
      end
    end

    it "should be false if the checked time is before the expired time" do
      [zr_daily, zr_weekly, zr_monthly_by_day_of_month, zr_monthly_by_day_of_week].each do |zr|
        zr.expired?(Time.parse('2013-06-01 00:00:00 -07:00')).should(be_false, "#{zr.repeat_type} expected ACTIVE")
        zr.expired?(Time.parse('2013-05-01 00:00:00 -07:00')).should(be_false, "#{zr.repeat_type} expected ACTIVE")
      end
    end
  end

  describe "#includes?" do
    context "giving a time" do # does the present time fall in the given timeframe?

      let(:zr) { ZoneRanger::Core.new('2013-04-01 23:01:00 -07:00', 60, "Pacific Time (US & Canada)") }

      context "in timeframe" do # present time is inside timeframe
        it "should be active" do
          validate_active(zr, '2013-04-01 23:01:01 -07:00')
          validate_active(zr, '2013-04-02 00:00:00 -07:00')
        end
      end
      context "outside timeframe" do # present time is outside timeframe
        it "should not be active" do
          validate_inactive(zr, '2013-04-01 23:00:01 -07:00')
          validate_inactive(zr, '2013-04-02 00:02:00 -07:00')
        end
      end

      context "over utc midnight" do
        let(:set_timeframe_over_two_days){ ZoneRanger::Core.new("2013-07-24 23:01 UTC", 120, "UTC", :repeat => :weekly, :ending => Time.parse("2013-07-25 UTC")) }

        it "should be active in timeframe" do
          validate_active(set_timeframe_over_two_days, "2013-07-24 23:02 UTC")
          validate_active(set_timeframe_over_two_days, "2013-07-25 01:00 UTC")
        end

        it "should not be active in timeframe" do
          validate_inactive(set_timeframe_over_two_days, "2013-07-24 23:00 UTC")
          validate_inactive(set_timeframe_over_two_days, "2013-07-25 01:02 UTC")
        end
      end

      context "repeated" do
        context "daily" do
          let(:zr_daily) { ZoneRanger::Core.new('2013-04-01 23:01:00 -07:00', 60, "Pacific Time (US & Canada)", :repeat => :daily) }
          let(:zr_daily_no_start_date) { ZoneRanger::Core.new('23:01:00 -07:00', 60, "Pacific Time (US & Canada)", :repeat => :daily) }

          it "should cover until midnight every day" do
            (1..8).each do |i|
              validate_active(zr_daily, "2013-04-0#{i} 23:59:01 -07:00")
              validate_active(zr_daily_no_start_date, "2013-04-0#{i} 23:59:01 -07:00")
            end
          end

          it "should cover after midnight every day" do
            (1..8).each do |i|
              validate_active(zr_daily, "2013-04-0#{i+1} 00:00:00 -07:00")
              validate_active(zr_daily_no_start_date, "2013-04-0#{i+1} 00:00:00 -07:00")
            end
          end

          it "should not cover after midnight from the day before if before starting time" do
            validate_inactive(zr_daily, "2013-03-31 00:00:00 -07:00")
            validate_active(zr_daily_no_start_date, "2013-03-31 00:00:00 -07:00")
          end
        end

        context "weekly" do
          let(:zr_weekly) { ZoneRanger::Core.new('2013-04-01 00:01:00 -07:00', 60, "Pacific Time (US & Canada)", :repeat => :weekly) }
          
          it "should cover only on the day of week, and in time range" do
            validate_active(zr_weekly, '2013-04-01 00:01:01 -07:00')
            validate_active(zr_weekly, '2013-04-01 00:59:59 -07:00')

            # next week
            validate_active(zr_weekly, '2013-04-08 00:01:01 -07:00')
            validate_active(zr_weekly, '2013-04-08 00:59:59 -07:00')
          end

          it "should not cover if on the day of week, but not in time range" do
            validate_inactive(zr_weekly, '2013-04-08 00:00:59 -07:00')
            validate_inactive(zr_weekly, '2013-04-08 01:02:59 -07:00')
          end

          it "should not cover if not on the day of week and in time range" do
            validate_inactive(zr_weekly, '2013-04-07 00:01:01 -07:00')
            validate_inactive(zr_weekly, '2013-04-07 00:59:59 -07:00')
          end
        end

        context "monthly" do
          context "day of the month" do

            let(:zr_monthly_dom) { ZoneRanger::Core.new('2013-04-01 00:01:00 -07:00', 60, "Pacific Time (US & Canada)", :repeat => :monthly_by_day_of_month) }

            it "should be active if on the day of the month of start_date and within the timeframe" do
              validate_active(zr_monthly_dom, '2013-05-01 00:02:00 -07:00')
              validate_active(zr_monthly_dom, '2013-05-01 00:59:00 -07:00')
              validate_active(zr_monthly_dom, '2013-06-01 00:02:00 -07:00')
              validate_active(zr_monthly_dom, '2013-06-01 00:59:00 -07:00')
            end
              
            it "should not be active if on the day of the month of start_date and within the timeframe but start_date is in the future" do
              validate_inactive(zr_monthly_dom, '2013-03-01 00:02:00 -07:00')
              validate_inactive(zr_monthly_dom, '2013-03-01 00:59:00 -07:00')
            end
            
            it "should not be active if within the timeframe but not on the day of the month" do
              validate_inactive(zr_monthly_dom, '2013-04-03 00:02:00 -07:00')
              validate_inactive(zr_monthly_dom, '2013-04-03 00:59:00 -07:00')
            end

          end

          context "day of the week" do
            let(:zr_monthly_dow) { ZoneRanger::Core.new('2013-04-01 00:01:00 -07:00', 60, "Pacific Time (US & Canada)", :repeat => :monthly_by_day_of_week) }

            it "should be active if on the same weekday and xth week and inside timeframe" do
              validate_active(zr_monthly_dow, "2013-04-01 00:02:00 -07:00")
              validate_active(zr_monthly_dow, "2013-04-01 01:00:00 -07:00")

              # next period
              validate_active(zr_monthly_dow, "2013-05-06 00:02:00 -07:00")
              validate_active(zr_monthly_dow, "2013-05-06 01:00:00 -07:00")
            end
            
            it "should not be active if on xth week and inside timeframe but not on same weekday" do
              validate_inactive(zr_monthly_dow, "2013-05-05 00:02:00 -07:00")
              validate_inactive(zr_monthly_dow, "2013-05-05 01:00:00 -07:00")
            end
            
            it "should not be active if on the same weekday and inside timeframe but not on xth week" do
              validate_inactive(zr_monthly_dow, "2013-04-08 00:02:00 -07:00")
              validate_inactive(zr_monthly_dow, "2013-04-08 01:00:00 -07:00")
            end
            
            it "should not be active if on the same weekday and xth week but outside timeframe" do
              validate_inactive(zr_monthly_dow, "2013-04-01 00:00:00 -07:00")
              validate_inactive(zr_monthly_dow, "2013-04-01 01:02:00 -07:00")

              # next period
              validate_inactive(zr_monthly_dow, "2013-05-06 00:00:00 -07:00")
              validate_inactive(zr_monthly_dow, "2013-05-06 01:02:00 -07:00")
            end
          end

        end
      end

    end

  end

end