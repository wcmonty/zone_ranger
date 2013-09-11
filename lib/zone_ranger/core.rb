require 'active_support/all'

module ZoneRanger
  class Core

    attr_reader :start_time_string, :repeat_type
    attr_reader :duration_in_seconds

    def initialize start_date_time, duration_in_minutes, timezone, options={}

      @start_time_string = start_date_time
      @duration_in_minutes = duration_in_minutes
      @duration_in_seconds = @duration_in_minutes * 60
      @timezone = timezone

      @ending = options.fetch(:ending, nil)

      @repeat_type = options.fetch(:repeat, nil)

    end

    def repeat?
      !!@repeat_type
    end

    def daily?
      @repeat_type == :daily
    end

    def weekly?
      @repeat_type == :weekly
    end

    def monthly_by_day_of_week?
      @repeat_type == :monthly_by_day_of_week
    end

    def monthly_by_day_of_month?
      @repeat_type == :monthly_by_day_of_month
    end

    def timezone_object
      ActiveSupport::TimeZone.new((@timezone || "UTC"))
    end
    
    def includes? time_point=Time.now.utc
      return false if not_started_yet?(time_point) || expired?(time_point)

      if repeat?
        included_in_repeating_timeframe? time_point
      else
        static_include? time_point
      end
    end

    def static_include? time_point
      zoned_time(time_point).between?(*time_range(time_point))
    end

    def expired? time=Time.now.utc
      return false unless @ending
      zoned_time(time) > zoned_end_date
    end

    def zoned_time time=nil
      tzone = timezone_object
      if time.nil?
        tzone.now
      else
        time.in_time_zone(tzone)
      end
    end

    def zoned_date time=Time.now.utc
      zoned_time(time).to_date
    end

    def zoned_end_date
      timezone_object.parse("#{@ending} 23:59:59 #{utc_offset}")
    end

    def utc_offset
      ActiveSupport::TimeZone.seconds_to_utc_offset(zoned_time.utc_offset)
    end

    def not_started_yet? time
      start_on > zoned_date
    end

    def start_on
      parsed_time_string.to_date
    end

    def started?
      !not_started_yet?
    end

    def time_range current_day=Time.now.utc, options={}
      
      offset = options.fetch(:offset, 0)

      start_date = if repeat?
        #if daily?
        # shift to the day being checked
        start_time = zoned_time(current_day + offset.days)
        start_time.to_date
        #end
      else
        parsed_time_string.to_date
      end

      b_start = timezone_object.parse(parsed_time_string.strftime("#{start_date} %H:%M")).in_time_zone(timezone_object)
      b_end = b_start + duration_in_seconds

      [b_start, b_end]
    end

    def parsed_time_string
      timezone_object.parse(start_time_string)
    end

    protected

    def included_in_repeating_timeframe? time_point
      repeat? && (daily? && include_for_daily?(time_point) ||
            weekly? && include_for_weekly?(time_point) ||
            monthly_by_day_of_week? && include_for_monthly_dow?(time_point) ||
            monthly_by_day_of_month? && include_for_monthly_dom?(time_point))
    end

    def include_for_daily? time_point
      zoned_time(time_point).between?(*time_range(time_point, :offset => -1)) || zoned_time(time_point).between?(*time_range(time_point))
    end

    def include_for_weekly? time_point
      start_date = zoned_time(time_point).to_date
      start_at, end_at = time_range(time_point)

      if Util.crosses_one_utc_midnight?(parsed_time_string, @duration_in_minutes)
        wday1 = parsed_time_string.wday
        wday2 = parsed_time_string.tomorrow.wday

        case start_date.wday
        when wday1
          zoned_time(time_point).between?(start_at, end_at)
        when wday2
          yesterday_start, yesterday_end = time_range(zoned_time(time_point), :offset => -1)
          zoned_time(time_point).between?(yesterday_start, yesterday_end)
        else false
        end
      else
        Util.wday_match?(start_at, parsed_time_string) && zoned_time(time_point).between?(start_at, end_at)
      end
    end

    def include_for_monthly_dow? time_point
      start_date = parsed_time_string.to_date

      start_week = Util.week_of_month(start_date)
      time_week = Util.week_of_month(zoned_time(time_point))

      start_week == time_week && include_for_weekly?(time_point)
    end

    def include_for_monthly_dom? time_point
      original_day = parsed_time_string.day
      today_day = zoned_time(time_point).day

      if today_day == original_day
        static_include? time_point
      elsif (today_day == parsed_time_string.tomorrow.day) && Util.crosses_one_utc_midnight?
        zoned_time(time_point).between?(*time_range(time_point, :offset => -1))
      else
        false
      end
    end

  end
end