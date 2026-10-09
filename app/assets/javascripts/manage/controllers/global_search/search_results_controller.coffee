class window.App.SearchResultsController extends Spine.Controller

  elements: 
    ".list-of-lines": "list"

  constructor: ->
    super
    @additionalData =
      accessRight: App.AccessRight
      currentUserRole: App.User.current.role
      currentInventoryPool: App.InventoryPool.current
    @pagination = new App.OrdersPaginationController {el: @list, fetch: @_fetch}
    do @reset

  reset: =>
    @records = {}
    @finished = false
    @list.html App.Render "manage/views/lists/loading"
    @_fetch 1, @list

  _fetch: (page, target)=>
    callback = _.after 2, => @render(target, @records[page], page)
    @fetch(page, target, callback).done (data, status, xhr) =>
      @pagination.set JSON.parse(xhr.getResponseHeader("X-Pagination"))
      records = (App[@model].find(datum.id) for datum in data)
      @records[page] = records
      @finished = true if data.length == 0
      do callback

  render: (target, data, page)=>
    if page == 1 and (not data? or data.length == 0)
      target.html App.Render "manage/views/lists/no_results"
      return
    target.removeClass "loading-page"
    target.html App.Render @templatePath, data, @additionalData
    if !@finished and @el.find(".loading-page").length == 0
      nextPage = page + 1
      @list.append App.Render("manage/views/lists/loading_page", nextPage, {page: nextPage})
