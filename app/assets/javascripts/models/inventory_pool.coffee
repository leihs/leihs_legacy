###
  
  InventoryPool

###

class window.App.InventoryPool extends Spine.Model

  @configure "InventoryPool", "id", "name", "default_contract_note", "borrow_reservation_advance_days", "transfer_buffer_before_pick_up"

  @hasMany "availabilities", "App.Availability", "inventory_pool_id"
  @hasMany "models", "App.Model", "inventory_pool_id"
  @hasMany "holidays", "App.Holiday", "inventory_pool_id"
  @hasOne "workday", "App.Workday", "inventory_pool_id"

  @extend Spine.Model.Ajax

  @url: "/inventory_pools"

  isClosedOn: (date)=>
    _.include(@workday().closedDays(), date.day()) or
      _.any(@holidays().all(), (h)->
        (date.isAfter(h.start_date) and date.isBefore(h.end_date)) or
          date.isSame(h.start_date) or
          date.isSame(h.end_date)
      )

  isVisitPossible: (date)=>
    # NOTE check if the maximum visits limit has been reached
    @workday().reached_max_visits.indexOf(moment(date).format("YYYY-MM-DD")) is -1

  hasEnoughReservationAdvanceDays: (date)=>
    # NOTE check number of days between order submission and hand over
    date >= moment().startOf('day').add(@borrow_reservation_advance_days || 0, 'days')

  # mirrors InventoryPool#orders_processing? (Ruby)
  ordersProcessingOn: (date)=>
    return false unless @workday().ordersProcessingDay(date)
    holiday = _.find(@holidays().all(), (h)->
      (date.isAfter(h.start_date) and date.isBefore(h.end_date)) or
        date.isSame(h.start_date) or
        date.isSame(h.end_date)
    )
    not holiday or holiday.orders_processing

  # mirrors InventoryPool#earliest_possible_pickup_date (Ruby): today counts
  # as the first advance day, closed days are skipped without counting but
  # still advanced past.
  earliestPossiblePickupDate: (advanceDays)=>
    date = moment().startOf('day')
    inAdvance = 0
    while (advanceDays > 0 and inAdvance < advanceDays) or @isClosedOn(date)
      inAdvance += 1 if @ordersProcessingOn(date)
      date = moment(date).add(1, 'days')
    date
