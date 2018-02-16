class window.App.TemplateAvailabilityController extends Spine.Controller

  elements:
    "#template-lines": "templateLines"

  events:
    "click [data-change-template-line]": "openBookingCalendar"
    "click [data-destroy-template-line]": "destroyTemplateLine"

  delegateEvents: ->
    super
    App.TemplateLine.on "change", @render

  fetchTotalBorrowableQuantities: (modelId, callback) =>
    $.ajax({
      url: '/borrow/total_borrowable_quantities',
      method: 'GET',
      dataType: 'json',
      data: {
        model_id: modelId,
        inventory_pool_ids: _.map(@inventoryPools, (ipContext) => ipContext.inventory_pool.id)
      },
      success: (data) => callback(data)
    })

  openBookingCalendar: (e) =>
    do e.preventDefault
    target = $(e.currentTarget)
    line = target.closest(".line")
    templateLine = App.TemplateLine.findByAttribute("model_link_id", line.data("model_link_id"))
    elData = target.data()
    @fetchTotalBorrowableQuantities elData["modelId"], (data) =>
      inventoryPools = _.map(@inventoryPools, (ipContext) =>
        tbq = _.find(data, (d) => ipContext.inventory_pool.id == d.inventory_pool_id)
        _.extend(ipContext, { total_borrowable: tbq.total_borrowable })
      )
      inventoryPools = _.select(inventoryPools, (ipContext) => ipContext.total_borrowable > 0)
      @renderBookingCalendar(
        _.extend(elData, {inventoryPools: inventoryPools}),
        templateLine
      )

  renderBookingCalendar: (elData, templateLine) =>
    jModal = $("<div class='modal ui-modal medium' role='dialog' tabIndex='-1' />")
    @modal = new App.Modal(
      jModal,
      () => ReactDOM.unmountComponentAtNode(jModal.get()[0])
    )
    ReactDOM.render(
      React.createElement(CalendarDialog,
        inventoryPools: elData["inventoryPools"]
        model: App.Model.find(elData["modelId"])
        initialStartDate: moment(elData["startDate"])
        initialEndDate: moment(elData["endDate"])
        initialQuantity: elData["quantity"]
        titel: _jed("Change %s", _jed("Entry"))
        buttonText: _jed("Save change")
        exclusiveCallback: (attrs) =>
          App.TemplateLine.update(
            templateLine.id,
            _.extend({}, attrs, {available: true})
          )
          @modal.destroyable()
          App.Modal.destroyAll true
      ),
      @modal.el.get()[0]
    )

  destroyTemplateLine: (e)=>
    do e.preventDefault
    target = $(e.currentTarget)
    line = target.closest(".line")
    templateLine = App.TemplateLine.findByAttribute("model_link_id", line.data("model_link_id"))
    if confirm _jed "%s will be removed from the template and not been added to your order.", templateLine.model().name()
      App.TemplateLine.destroy templateLine.id
      if @templateLines.find(".line").length == 0
        document.location = "/borrow/templates"
    return false

  render: =>
    @templateLines.html App.Render "borrow/views/templates/availability/grouped_lines", App.Template.first().groupedLines()
