class window.App.OrdersEditController extends Spine.Controller

  elements:
    "#status": "status"
    "#lines": "reservationsContainer"
    "#purpose": "purposeContainer"
    "#reject-order": "rejectButton"
    "#approve-order": "approveButton"

  events:
    "click #edit-purpose.button": "editPurpose"
    "click #swap-user": "swapUser"
    "click #approve-with-comment": "approveOrderWithComment"
    "click [data-destroy-line]": "validateLineDeletion"
    "click [data-destroy-lines]": "validateLineDeletion"
    "click [data-destroy-selected-lines]": "validateLineDeletion"

  constructor: ->
    super
    do @setupLineSelection
    do @fetchAvailability
    do @setupAddLine
    new App.SwapModelController {el: @el, user: @order.user()}
    new App.TimeLineController {el: @el}
    new App.OrdersApproveController {el: @el, done: @orderApproved}
    new App.OrdersRejectController {el: @el, async: false}
    new App.ReservationsDestroyController {el: @el, callback: => @render(true) }
    new App.ReservationsEditController {el: @el, user: @order.user(), order: @order}
    new App.ModelCellTooltipController {el: @el}

  delegateEvents: =>
    super
    App.Reservation.on "change destroy", @fetchAvailability
    App.Order.on "refresh", @fetchAvailability

  setupAddLine: =>
    that = @

    reservationsAddController = new App.ReservationsAddController
      el: @el.find("#add")
      user: @order.user()
      status: @status
      order: @order
      modelsPerPage: 20
      callback: => @render(true)

    onChangeCallback = (value) ->
      console.log 'onChangeCallback'
      that.inputValue = value
      that.autocompleteController.setProps(isLoading: true)
      reservationsAddController.search value, (data)->
        that.autocompleteController.setProps(searchResults: data, isLoading: false)

    # create and mount the input field:
    props =
      onChange: _.debounce(onChangeCallback, 300)
      onSelect: reservationsAddController.select
      isLoading: false
      placeholder: _jed("Inventory code, model name, search term")

    @autocompleteController =
      new App.HandOverAutocompleteController \
        props,
        @el.find("#add-input")[0]

    @autocompleteController._render()

    window.autocompleteController = @autocompleteController

    reservationsAddController.setupAutocomplete(@autocompleteController)

  setupLineSelection: =>
    @lineSelection = new App.LineSelectionController
      el: @el

  validateLineDeletion: (e)=>
    ids = if $(e.currentTarget).closest("[data-id]").length
        [$(e.currentTarget).closest("[data-id]").data("id")]
      else if $(e.currentTarget).data("ids")?
        $(e.currentTarget).data("ids")
      else
        App.LineSelectionController.selected
    if @order.reservations().all().length <= ids.length
      App.Flash
        type: "error"
        message: _jed "You cannot delete all reservations of an order. Perhaps you want to reject it instead?"
      e.stopImmediatePropagation()
      return false

  fetchAvailability: =>
    @render false
    @status.html App.Render "manage/views/availabilities/loading"
    App.Availability.ajaxFetch
      data: $.param
        model_ids: _.uniq(_.map(@order.reservations().all(), (l)->l.model().id))
        user_id: @order.user_id
    .done (data)=>
      @status.html App.Render "manage/views/availabilities/loaded"
      @render true

  render: (renderAvailability)=>
    @reservationsContainer.html App.Render "manage/views/reservations/grouped_lines", @order.groupedLinesByDateRange(true),
      linePartial: "manage/views/reservations/order_line"
      renderAvailability: renderAvailability
    do @lineSelection.restore

  editPurpose: =>
    new App.OrdersEditPurposeController
      order: @order
      callback: @renderPurpose

  swapUser: =>
    jModal = $("<div class='modal medium hide fade ui-modal padding-inset-m padding-horizontal-l' role='dialog' tabIndex='-1' />")
    @modal = new App.Modal(
      jModal,
      () =>
        ReactDOM.unmountComponentAtNode(jModal.get()[0])
    )
    @swapOrderUserDialog = ReactDOM.render(
      React.createElement(SwapOrderUserDialog, {
          data: {},
          other: {
            order: @order,
            manageContactPerson: true,
            user: @order.user()
          }
      }),
      @modal.el.get()[0]
    )
    @el = @modal.el

  renderPurpose: => @purposeContainer.html @order.purpose

  approveOrderWithComment: =>
    new App.OrdersApproveWithCommentController
      trigger: @approveButton
      order: @order

  orderApproved: =>
    window.location = "/manage/#{App.InventoryPool.current.id}/daily?flash[success]=#{_jed('Order approved')}"
