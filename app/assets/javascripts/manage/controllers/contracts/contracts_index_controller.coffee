class window.App.ContractsIndexController extends Spine.Controller

  elements:
    "#contracts": "list"

  constructor: ->
    super
    new App.LinesCellTooltipController {el: @el}
    new App.UserCellTooltipController {el: @el}
    @pagination = new App.OrdersPaginationController {el: @list, fetch: @fetch}
    @search = new App.ListSearchController {el: @el.find("#list-search"), reset: @reset}
    @filter = new App.ListFiltersController {el: @el.find("#list-filters"), reset: @reset}
    @range = new App.ListRangeController {el: @el.find("#list-range"), reset: @reset}
    @tabs = new App.ListTabsController {el: @el.find("#list-tabs"), reset: @reset, data:{status: @status}}
    do @reset

  reset: =>
    @contracts = {}
    @finished = false
    @list.html App.Render "manage/views/lists/loading"
    @fetch 1, @list
    @pagination.page = 1

  fetch: (page, target)=>
    @fetchContracts(page).done =>
      @fetchUsers(page).done =>
        @fetchReservations page, =>
          @render target, @contracts[page], page

  fetchContracts: (page)=>
    data = $.extend @tabs.getData(), $.extend @filter.getData(),
      disable_total_count: true
      search_term: @search.term()
      page: page
      range: @range.get()
    data = $.extend data, { from_verifiable_users: true } if App.User.current.role == "group_manager"
    App.Contract.ajaxFetch({ data: $.param data })
    .done (data, status, xhr) =>
      @pagination.set JSON.parse(xhr.getResponseHeader("X-Pagination"))
      @finished = true if data.length == 0
      contracts = (App.Contract.find(datum.id) for datum in data)
      @contracts[page] = contracts

  fetchReservations: (page, callback)=>
    ids = _.map @contracts[page], (o) -> o.id
    do callback unless ids.length
    done = _.after Math.ceil(ids.length/50), callback
    _(ids).each_slice 50, (slice)=>
      App.Reservation.ajaxFetch
        data: $.param
          contract_ids: slice
      .done done

  fetchUsers: (page)=>
    ids = _.filter (_.map @contracts[page], (c) -> c.user_id), (id) -> not App.User.exists(id)?
    return {done: (c)=>c()} unless ids.length
    App.User.ajaxFetch
      data: $.param
        ids: _.uniq(ids)
        all: true
    .done (data)=>
      users = (App.User.find datum.id for datum in data)
      App.User.fetchDelegators users

  render: (target, data, page)=>
    target.html App.Render "manage/views/contracts/line", data, { accessRight: App.AccessRight, currentUserRole: App.User.current.role }
    if !@finished && $('.loading-page').length == 0
      nextPage = page + 1
      @list.append(App.Render("manage/views/lists/loading_page", nextPage, {page: nextPage}))
