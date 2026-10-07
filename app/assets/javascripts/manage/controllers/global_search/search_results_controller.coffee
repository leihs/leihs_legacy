class window.App.SearchResultsController extends Spine.Controller

  elements: 
    ".list-of-lines": "list"

  constructor: ->
    super
    @additionalData =
      accessRight: App.AccessRight
      currentUserRole: App.User.current.role
      currentInventoryPool: App.InventoryPool.current
    @pagination = new App.OnDemandPaginationController {el: @list, fetch: @_fetch}
    do @reset

  reset: =>
    @records = {}
    @finished = false
    @list.html App.Render "manage/views/lists/loading_page", 1, {page: 1}
    @pagination.loadPage @list.find(".loading-page")

  _fetch: (page, target)=>
    @fetchRecords(page)
    .then (data, status, xhr) =>
      @pagination.set JSON.parse(xhr.getResponseHeader("X-Pagination"))
      @records[page] = (App[@model].find(datum.id) for datum in data)
      @finished = data.length < @pagination.perPage
      @fetchRelated @records[page]
    .then =>
      @render(target, @records[page], page)

  fetchRelated: => $.when()

  render: (target, data, page)=>
    if page == 1 and (not data? or data.length == 0)
      @list.html App.Render "manage/views/lists/no_results"
      return
    target.removeClass "loading-page"
    target.html App.Render @templatePath, data, @additionalData
    @pagination.appendNextPage @list, page unless @finished
