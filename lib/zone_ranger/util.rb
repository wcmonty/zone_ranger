module ZoneRanger
  class Util

    def self.week_of_month time
      day_num = time.day
      days_in_month = Time.days_in_month(time.month)
      
      if day_num < 8
        1
      elsif day_num < 15
        2
      elsif day_num < 22
        3
      elsif day_num < days_in_month - 7
        4 # fourth but not last
      else
        :last # last
      end
    end

    def self.crosses_one_utc_midnight? start, duration
      # a utc midnight is when the start day is different the blackout ends on
      day1 = start.utc.to_date
      day2 = (start + duration.minutes).utc.to_date
      day1 != day2
    end

    def self.wday_match? date1, date2
      date1.wday == date2.wday
    end

  end
end