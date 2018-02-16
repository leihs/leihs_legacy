class window.App.UnsubmittedCustomerOrderShowController extends Spine.Controller

  elements:
    "#current-order-lines": "reservationsContainer"
    ".emboss.red": "conflictsWarning"

  events:
    "click [data-change-order-lines]": "openBookingCalendar"

  constructor: ->
    super
    unless App.CustomerOrder.timedOut
      @timeoutCountdown = new App.TimeoutCountdownController
        el: @el.find("#timeout-countdown")
        refreshTarget: @el.find("#timeout-countdown")

  openBookingCalendar: (e) =>
    do e.preventDefault
    data = $(e.target).data()
    props =
      reservations: _.map(data["ids"], (id) -> App.Reservation.find(id))
      inventoryPools: [@getInventoryPoolContext(data["inventoryPoolId"], data["totalBorrowable"])]
      model: App.Model.find(data["modelId"])
      initialStartDate: moment(data["startDate"])
      initialEndDate: moment(data["endDate"])
      initialQuantity: data["quantity"]
      finishCallback: (_data) => window.location.href = "/borrow/order"
    @renderBookingCalendar(props)

  getInventoryPoolContext: (id, totalBorrowable) =>
    ipContext = _.find(@inventoryPools, (ipContext) -> ipContext.inventory_pool.id == id)
    _.extend(ipContext, {total_borrowable: totalBorrowable})

  getStartDate: (reservationIds, inventoryPools) =>
    moment(App.Reservation.find(reservationIds[0]).start_date)

  getEndDate: (reservationIds) =>
    moment(App.Reservation.find(reservationIds[0]).end_date)

  renderBookingCalendar: (props) =>
    jModal = $("<div class='modal ui-modal medium' role='dialog' tabIndex='-1' />")
    @modal = new App.Modal(
      jModal,
      () => ReactDOM.unmountComponentAtNode(jModal.get()[0])
    )
    ReactDOM.render(
      React.createElement(CalendarDialog, props),
      @modal.el.get()[0]
    )
