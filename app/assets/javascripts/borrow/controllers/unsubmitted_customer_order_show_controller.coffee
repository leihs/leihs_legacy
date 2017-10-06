class window.App.UnsubmittedCustomerOrderShowController extends Spine.Controller

  elements:
    "#current-order-lines": "reservationsContainer"
    ".emboss.red": "conflictsWarning"

  events:
    "click [data-change-order-lines]": "changeReservations"

  constructor: ->
    super
    unless App.CustomerOrder.timedOut
      @timeoutCountdown = new App.TimeoutCountdownController
        el: @el.find("#timeout-countdown")
        refreshTarget: @el.find("#timeout-countdown")
    
  delegateEvents: =>
    super
    App.Reservation.bind "refresh", (data)=>
      do @render

  changeReservations: (e)=>
    do e.preventDefault
    target = $(e.currentTarget)
    reservations = _.map target.data("ids"), (id) -> App.Reservation.find id
    quantity = _.reduce reservations, ((mem, l)-> mem + l.quantity), 0
    new App.ReservationsChangeController
      modelId: target.data("model-id")
      reservations: reservations
      quantity: quantity
      startDate: target.data("start-date")
      endDate: target.data("end-date")
      titel: _jed("Change %s", _jed("Order"))
      buttonText: _jed("Save change")
      withoutLines: true
    return false

  render: =>
    reservations = App.Reservation.all()
    @reservationsContainer.html App.Render "borrow/views/order/grouped_and_merged_lines", App.Modules.HasLines.groupByDateAndPool(reservations, true)
    @conflictsWarning.addClass("hidden") if _.all reservations, (l) -> l.available()
