module TimeWindows
  def time_window_min
    reservations.minimum(:start_date) || Time.zone.today
  end

  def time_window_max
    reservations.maximum(:end_date) || Time.zone.today
  end
end
