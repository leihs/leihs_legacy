module DateHelper

  def interval(start_date, end_date)
    interval = Integer(end_date - start_date).abs + 1
    pluralize(interval, _('Day'), _('Days'))
  end

end
