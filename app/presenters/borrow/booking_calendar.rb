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
      @model.availability_in(@inventory_pool, exclude_reservations: @reservations)
    @changes = @availability.changes.to_a.sort_by(&:first)
    @init_date = @start_date - 1.day
    @total_borrowable_quantity = \
      @model.total_borrowable_items_for_user_and_pool(
        @user,
        @inventory_pool,
        ensure_non_negative_general: true
      )
    @availabilities_per_day = availabilities_per_day
    @total_borrowable_quantities_per_day = total_borrowable_quantities_per_day
    @visits_per_day = visits_per_day
  end

  def list
    @total_borrowable_quantities_per_day.map.with_index \
      do |total_borrow_qty_per_day, i|
      quantity = \
        (@availabilities_per_day[i] or total_borrow_qty_per_day)[:quantity]
      @visits_per_day[i].merge(quantity: quantity)
    end
  end

  private

  def total_borrowable_quantities_per_day
    (@start_date..@end_date).map do |d|
      { d: d, quantity: @total_borrowable_quantity }
    end
  end

  def availabilities_per_day
    result = @changes.drop(1).reduce([[@init_date, 0]]) do |memo, obj|
      s_date = memo.last.first + 1.day
      e_date = obj.first - 1.day
      qty = \
        @availability
        .maximum_available_in_period_summed_for_groups(s_date,
                                                       e_date,
                                                       @group_ids)
      new_dates = (s_date..e_date).map { |d| [d, qty] }
      memo + new_dates
    end
    result.shift(1)
    result.map { |fst, snd| { d: fst, quantity: snd } }
  end

  def visits_per_day
    BookingCalendarVisitsQuery
      .new(inventory_pool_id: @inventory_pool.id,
           start_date: @start_date_string,
           end_date: @end_date_string)
      .run
  end

end
