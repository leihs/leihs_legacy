class window.App.ReservationsCreateController extends window.App.ReservationsChangeController

  # @override
  getAvailability: (inventoryPool)=> @availabilities[inventoryPool.id]

  # @override
  setupQuantity: -> true

  # @override
  selectFirstInventoryPool: ->
    inventoryPoolIds = App.ModelsIndexIpSelectorController.activeInventoryPoolIds
    for id in inventoryPoolIds
      option = @inventoryPoolSelect.find "option[data-id='#{id}']"
      if option.length
        option.prop "selected", true
        break

  # @override
  setupDates: =>
    if sessionStorage.startDate?
      @startDateEl.val(
        moment(sessionStorage.startDate, "DD.MM.YYYY").format("YYYY-MM-DD")
      )
    else
      @startDateEl.val moment().format("YYYY-MM-DD")
    if sessionStorage.endDate?
      @endDateEl.val(
        moment(sessionStorage.endDate, "DD.MM.YYYY").format("YYYY-MM-DD")
      )
    else
      @endDateEl.val moment().add(1, "days").format("YYYY-MM-DD")

  # @override
  store: => 
    quantity = @quantityEl.val()
    finish = _.after quantity, @done
    for time in [1..quantity]
      @createReservation().done (datum) =>
        reservation = App.Reservation.find datum.id
        do finish
