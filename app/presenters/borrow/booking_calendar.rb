class Borrow::BookingCalendar < ApplicationPresenter
  def initialize(inventory_pool,
                 model,
                 user,
                 start_date_string,
                 end_date_string,
                 reservations = [])
    @inventory_pool = inventory_pool
    @model = model
    @user = user
    @reservations = reservations
    @start_date_string = start_date_string
    @start_date = Date.parse(@start_date_string)
    @end_date_string = end_date_string
    @end_date = Date.parse(@end_date_string)
    @group_ids = user.entitlement_groups.map(&:id)
    @availability = \
      @model.availability_in(@inventory_pool,
                             exclude_reservations: @reservations,
                             sanitize_invalid_entitled_quantity: true)
    @changes = @availability.changes.to_a.sort_by(&:first)
    @availabilities_per_day = availabilities_per_day
    @visits_per_day = visits_per_day
  end

  def list
    @availabilities_per_day.map.with_index do |qty_per_day_hash, i|
      qty_per_day_hash.merge(@visits_per_day[i])
    end
  end

  private

  def availabilities_per_day
    change_dates = @changes.map(&:first)
    change_dates_between_start_and_end_date = \
      change_dates.select { |d| @start_date < d && d < @end_date }

    dates = change_dates_between_start_and_end_date
    dates.unshift(@start_date).push(@end_date) # !

    # [[@start_date, date_1], [date_1, date_2], [date_2, @end_date], [@end_date, @start_date]]
    dates_tuples = dates.zip(dates.rotate)
    # remove [@end_date, @start_date] from the end
    dates_tuples.pop # !
    # remove date overlappings
    dates_tuples.map! { |d1, d2| [d1, d2 - 1.day] }

    result = dates_tuples.map do |d1, d2|
      qty = \
        @availability
        .maximum_available_in_period_summed_for_groups(d1, d2, @group_ids,
                                                       sanitize_negative: true)
        .to_i # past date intervals return nil (nil.to_i == 0)
      (d1..d2).map { |d| { d: d.to_s, quantity: qty } }
    end.flatten

    result
  end

  def visits_per_day
    ::QueryObjects::BookingCalendarVisits
      .new(inventory_pool_id: @inventory_pool.id,
           start_date: @start_date_string,
           end_date: @end_date_string)
      .run
      .map(&:symbolize_keys)
  end

end
