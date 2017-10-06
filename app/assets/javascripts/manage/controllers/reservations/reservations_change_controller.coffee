class window.App.ReservationsChangeController extends window.App.ManageBookingCalendarDialogController

  createReservation: =>
    App.Reservation.createOne
      model_id: _.first(@models).id
      start_date: @getStartDate().format("YYYY-MM-DD")
      end_date: @getEndDate().format("YYYY-MM-DD")
      order_id: @order?.id
      user_id: (@order?.user?.id or @user.id)
      inventory_pool_id: (@order?.inventory_pool?.id or App.InventoryPool.current.id)
      state: (@order?.state or "approved")
      quantity: 1
    .fail (e)=>
      @fail(e)

  # overwrite
  done: (data)=>
    App.Reservation.trigger "refresh", (App.Reservation.find datum.id for datum in data)
    App.Order.trigger "refresh"
    super

  # overwrite
  store: =>
     # the check for the existence of order is needed for distinguishing the take backs, for which only the changing of end date should be possible (see @changeRange and @startDateDisabled). @order is not initialized on the take back page, because there may be different order
    if @order? or @hand_over?
      if @models.length == 1
        do @storeItemLine
      else if @models.length == 0
        do @storeOptionLine
      else
        do @changeRange
    else
      do @changeRange
    
  storeItemLine: =>
    difference = @getQuantity() - @quantity
    if difference < 0  # destroy reservations in the amount of the quantity difference
      reservationsToBeDestroyed = @reservations[0..(Math.abs(difference)-1)]
      deletionDone = _.after reservationsToBeDestroyed.length, @changeRange
      @reservations = _.reject @reservations, (l)-> _.include(reservationsToBeDestroyed, l)
      for line in reservationsToBeDestroyed
        do (line)->
          App.Reservation.ajaxChange(line, "destroy", {}).done =>
            line.remove()
            do deletionDone
    else if difference > 0 # create new reservations in the amount of the quantity difference
      finish = _.after difference, @changeRange
      for time in [1..difference]
        @createReservation()
        .done (datum) =>
          @reservations.push App.Reservation.find datum.id
          App.Reservation.trigger "refresh"
          App.Order.trigger "refresh"
          do finish
    else # no quantity difference, try to change the range
      do @changeRange

  storeOptionLine: =>
    if @getQuantity()?
      line = _.first @reservations
      line.updateAttributes 
        quantity: @getQuantity()
        start_date: @getStartDate().format("YYYY-MM-DD")
        end_date: @getEndDate().format("YYYY-MM-DD")
      @done line.order()
    else 
      do @changeRange

  changeRange: => 
    if @getStartDate().format("YYYY-MM-DD") != @startDate or @getEndDate().format("YYYY-MM-DD") != @endDate
      App.Reservation.changeTimeRange(@reservations, (@getStartDate() unless @startDateDisabled), @getEndDate())
      .done(@done)
      .fail @fail
    else
      do @done
