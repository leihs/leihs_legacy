class window.App.OrdersIndexController extends Spine.Controller

  elements:
    "#contracts": "list"

  constructor: ->
    super
    new App.LinesCellTooltipController {el: @el}
    new App.UserCellTooltipController {el: @el}
    new App.OrdersApproveController {el: @el}
    new App.OrdersRejectController {el: @el, async: true, callback: @orderRejected}
    @pagination = new App.OnDemandPaginationController {el: @list, fetch: @fetch}
    @search = new App.ListSearchController {el: @el.find("#list-search"), reset: @reset}
    @filter = new App.ListFiltersController {el: @el.find("#list-filters"), reset: @reset}
    @range = new App.ListRangeController {el: @el.find("#list-range"), reset: @reset}
    @tabs = new App.ListTabsController {el: @el.find("#list-tabs"), reset: @reset, data:{status: @status}}
    do @reset

  reset: =>
    @orders = {}
    @finished = false
    @list.html App.Render "manage/views/lists/loading_page", 1, {page: 1}
    @pagination.loadPage @list.find(".loading-page")

  fetch: (page, target)=>
    @fetchOrders(page)
    .then =>
      @fetchUsers(page)
    .then =>
      @fetchReservations(page)
    .then =>
      @render target, @orders[page], page if @orders[page]

  fetchOrders: (page)=>
    data = $.extend @tabs.getData(), $.extend @filter.getData(),
      disable_total_count: true
      search_term: @search.term()
      page: page
      range: @range.get()
      order_by_created_at_group_by_user: true

    if not data['to_be_verified'] and App.User.current.role == "group_manager"
      data = $.extend data, { from_verifiable_users: true }

    if not data['no_verification_required'] and App.User.current.role != "group_manager"
      data = $.extend data, { to_be_verified: true }

    App.Order.ajaxFetch({ data: $.param data })
    .done (data, status, xhr) =>
      @pagination.set JSON.parse(xhr.getResponseHeader("X-Pagination"))
      @finished = data.length < @pagination.perPage
      orders = (App.Order.find(datum.id) for datum in data)
      @orders[page] = orders

  fetchReservations: (page)=>
    ids = _.map @orders[page], (o) -> o.id
    requests = []
    _(ids).each_slice 50, (slice)=>
      requests.push App.Reservation.ajaxFetch
        data: $.param
          order_ids: slice
    $.when requests...

  fetchUsers: (page)=>
    ids = _.filter (_.map @orders[page], (c) -> c.user_id), (id) -> not App.User.exists(id)?
    return $.when() unless ids.length
    App.User.ajaxFetch
      data: $.param
        ids: _.uniq(ids)
        all: true
    .done (data)=>
      users = (App.User.find datum.id for datum in data)
      App.User.fetchDelegators users

  render: (target, data, page)=>
    target.removeClass('loading-page')
    target.html App.Render "manage/views/orders/line", data, { accessRight: App.AccessRight, currentUserRole: App.User.current.role }
    @pagination.appendNextPage @list, page unless @finished
