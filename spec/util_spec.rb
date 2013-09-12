require 'spec_helper'

describe ZoneRanger::Util do
  it "should pass" do
  end

  describe '#crosses_one_utc_midnight?' do
    #   let(:does_cross) { Factory(:check_blackout_period, 
    #         :repeat_type => "daily",
    #         :start_time => "19:58", :end_time => "1:38", :start_date => nil)}
    #   let(:does_not_cross) { Factory(:check_blackout_period, 
    #         :repeat_type => "daily",
    #         :start_time => "10:58", :end_time => "11:38", :start_date => nil)}
    #   let(:crossing_utc_weekly_blackout) { Factory(:check_blackout_period, :repeat_type => "weekly",
    #     :start_time => "19:58", :end_time => "1:30", :start_date => Date.parse('2013-07-17'))}

    #   it "should cross one midnight" do
    #     does_cross.send(:crosses_one_utc_midnight?).should be_true
    #     does_not_cross.send(:crosses_one_utc_midnight?).should be_false
    #     crossing_utc_weekly_blackout.send(:crosses_one_utc_midnight?).should be_true
    #   end
    # end
  end
end