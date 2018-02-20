class window.App.ModelsIndexController extends Spine.Controller

  elements:
    "#model-list": "list"

  events:
    "click [data-create-order-line]": "openBookingCalendar"

  constructor: ->
    super
    @models = _.map @models, (m)=> new App.Model m
    @searchTerm = @params.search_term
    @reset = new App.ModelsIndexResetController {el: @el.find("#reset-all-filter"), reset: @resetAllFilter, isResetable: @isResetable}
    @ipSelector = new App.ModelsIndexIpSelectorController {el: @el.find("#ip-selector"), onChange: => do @resetAndFetchModels}
    @sorting = new App.ModelsIndexSortingController {el: @el.find("#model-sorting"), onChange: => do @resetAndFetchModels}
    @search = new App.ModelsIndexSearchController {el: @el.find("#model-list-search"), onChange: => do @resetAndFetchModels}
    @period = new App.ModelsIndexPeriodController {el: @el.find("#period"), onChange: => do @periodChange}
    @pagination = new App.ModelsIndexPaginationController {el: @list, onChange: (page)=> @fetchModels(page)}
    @tooltips = new App.ModelsIndexTooltipController {el: @list}
    do @delegateEvents

    @sessionStorage = new App.SessionStorageController
      el: @el
      ipSelector: @ipSelector
      sorting: @sorting
      search: @search
      period: @period
    unless @sessionStorage.isEmpty()
      @sessionStorage.restoreFilters(callback: @resetAndFetchModels)

  delegateEvents: =>
    super
    App.PlainAvailability.on "refresh", @render
    App.Model.on(
      "ajaxSuccess",
      (e,status,xhr) =>
        @pagination.setData JSON.parse(xhr.getResponseHeader("X-Pagination"))
    )

  openBookingCalendar: (e)=>
    do e.preventDefault
    modelId = $(e.target.closest("[data-id]")).data("id")
    @fetchTotalBorrowableQuantities modelId, (data) =>
      inventoryPools = _.select(@inventoryPoolsForCalendar, (ipContext) =>
        _.contains(@ipSelector.activeInventoryPoolIds(), ipContext.inventory_pool.id)
      )
      console.log(@ipSelector.activeInventoryPoolIds())
      console.log(inventoryPools)
      inventoryPools = _.map(inventoryPools, (ipContext) =>
        tbq = _.find(data, (d) => ipContext.inventory_pool.id == d.inventory_pool_id)
        _.extend(ipContext, { total_borrowable: tbq.total_borrowable })
      )
      console.log(inventoryPools)
      inventoryPools = _.select(inventoryPools, (ipContext) => ipContext.total_borrowable > 0)
      console.log(inventoryPools)
      @renderBookingCalendar(modelId, inventoryPools)

  renderBookingCalendar: (modelId, inventoryPools)=>
    jModal = $("<div class='modal ui-modal medium' role='dialog' tabIndex='-1' />")
    @modal = new App.Modal(
      jModal,
      () => ReactDOM.unmountComponentAtNode(jModal.get()[0])
    )
    period = @period.getPeriod()
    ReactDOM.render(
      React.createElement(CalendarDialog,
        model: App.Model.find(modelId)
        inventoryPools: inventoryPools
        startDate: moment(period?.start_date or moment()),
        endDate: moment(period?.end_date or moment().add(1, 'day')),
        addButtonSuccessCallback: =>
          App.Reservation.trigger "refresh"
          @modal.destroyable()
          App.Modal.destroyAll true
      ),
      @modal.el.get()[0]
    )

  fetchTotalBorrowableQuantities: (modelId, callback) =>
    $.ajax({
      url: '/borrow/total_borrowable_quantities',
      method: 'GET',
      dataType: 'json',
      data: {
        model_id: modelId,
        inventory_pool_ids: @ipSelector.activeInventoryPoolIds()
      },
      success: (data) => callback(data)
    })

  periodChange: =>
    do @reset.validate
    @tooltips.tooltips = {}
    if @period.getPeriod()?
      @sessionStorage.update()
      do @loading
      do @fetchAvailability
    else
      App.PlainAvailability.deleteAll()
      do @render

  resetAndFetchModels: ({clearSessionStorage} = {clearSessionStorage: false}) =>
    do @reset.validate
    do @loading
    if clearSessionStorage
      @sessionStorage.clear()
    else
      @sessionStorage.update()
    @models = []
    @pagination.page = 1
    @tooltips.tooltips = {}
    do @fetchModels

  isResetable: =>
    @search.is_resetable() or @sorting.is_resetable() or @period.is_resetable() or @ipSelector.is_resetable()

  resetAllFilter: =>
    @ipSelector.reset()
    @sorting.reset()
    @search.reset()
    @period.reset()
    @resetAndFetchModels(clearSessionStorage: true)

  fetchModels: (page)=>
    $.extend @params, {inventory_pool_ids: @ipSelector.activeInventoryPoolIds()}
    $.extend @params, @sorting.getCurrentSorting()
    do @extendParamsWithSearchTerm
    params = _.clone @params
    if page?
      params.page = page
    App.Model.ajaxFetch
      data: $.param params
    .done (data)=>
      @models = @models.concat (App.Model.find(datum.id) for datum in data)
      if @period.getPeriod()? then do @fetchAvailability else do @render

  fetchAvailability: =>
    model_ids = _.map @models, (m)=> m.id
    @currentStartDate = @period.getPeriod().start_date
    @currentEndDate = @period.getPeriod().end_date
    App.PlainAvailability.fetch
      data: $.param
        start_date: @period.getPeriod().start_date
        end_date: @period.getPeriod().end_date
        model_ids: model_ids
        inventory_pool_ids: @ipSelector.activeInventoryPoolIds()

  render: =>
    @list.html App.Render "borrow/views/models/index/line", @models, {inventory_pool_ids: @ipSelector.activeInventoryPoolIds()}
    do @pagination.render

  loading: =>
    @list.html App.Render "borrow/views/models/index/loading"

  extendParamsWithSearchTerm: =>
    if @searchTerm?
      if @search.getInputText().search_term?
        @params.search_term = "#{@searchTerm} #{@search.getInputText().search_term}"
      else
        @params.search_term = @searchTerm
    else
      $.extend @params, @search.getInputText()
