class window.App.OnDemandPaginationController extends Spine.Controller

  events:
    "inview .page:not(.fetched)": "inview"
    "click .page-load-retry": "retry"

  set: (data)=>
    @perPage = data.per_page

  inview: (e)=>
    @loadPage $(e.currentTarget)

  retry: (e)=>
    e.preventDefault()
    @loadPage $(e.currentTarget).closest(".loading-page")

  loadPage: (target)=>
    @restoreSpinner target
    target.addClass "fetched"
    request = @fetch target.data("page"), target
    if request?.fail
      request.fail => @showPageError target

  restoreSpinner: (target)=>
    page = target.data("page")
    html = App.Render("manage/views/lists/loading_page", page, {page: page})
    target.html $(html).html()

  showPageError: (target)=>
    target.html App.Render("manage/views/lists/page_load_error")

  appendNextPage: (list, page)=>
    return if @el.find(".loading-page").length
    nextPage = page + 1
    list.append App.Render("manage/views/lists/loading_page", nextPage, {page: nextPage})
