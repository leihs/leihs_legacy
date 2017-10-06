class window.App.OrdersPaginationController extends Spine.Controller

  events:
    "inview .page:not(.fetched)": "inview"

  set: (data)=>
    @perPage = data.per_page

  inview: (e)=>
    target = $(e.currentTarget)
    target.addClass "fetched"
    @fetch target.data("page"), target
