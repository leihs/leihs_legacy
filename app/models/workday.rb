class Workday < ApplicationRecord

  belongs_to :inventory_pool, inverse_of: :workday

  # used in templates
  DAYS = %w(monday tuesday wednesday thursday friday saturday sunday)

  WORKDAYS = %w(sunday monday tuesday wednesday thursday friday saturday)
  
  def open_on?(date)
    return false if date.nil?

    case date.wday
    when 1
      return monday
    when 2
      return tuesday
    when 3
      return wednesday
    when 4
      return thursday
    when 5
      return friday
    when 6
      return saturday
    when 0
      return sunday
    else
      return false # Should not be reached
    end
  end

  def previous_open_date(date = Time.zone.today)
    unless closed_days.size == 7
      until open_on?(date -= 1.day); end
      date
    end
  end

  def next_open_date(date = Time.zone.today)
    unless closed_days.size == 7
      until open_on?(date += 1.day); end
      date
    end
  end

  def closed_days
    days = []
    days << 0 unless sunday
    days << 1 unless monday
    days << 2 unless tuesday
    days << 3 unless wednesday
    days << 4 unless thursday
    days << 5 unless friday
    days << 6 unless saturday
    days
  end

  def workdays=(wdays)
    wdays.each_pair do |k, v|
      write_attribute(WORKDAYS[k.to_i], v['open'].to_i)
      max_visits[k] = v['max_visits'].presence
    end
  end

  def render_for_email_template
    DAYS.inject([]) do |res, d|
      res << "#{_(d.capitalize)}: #{send(d) ? send("#{d}_info") : _('closed')}"
    end.join("\n")
  end

  def max_visits_on(weekday_number)
    max_visits[weekday_number.to_s]
  end

  def total_visits_by_date
    inventory_pool.visits.group_by(&:date)
  end

  def reached_max_visits
    dates = []
    total_visits_by_date.each_pair do |date, visits|
      next if date.past? \
        or max_visits_on(date.wday).nil? \
        or visits.size < max_visits_on(date.wday).to_i
      dates << date
    end
    dates.sort
  end

end
