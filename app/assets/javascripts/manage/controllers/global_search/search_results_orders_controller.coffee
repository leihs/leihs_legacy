#= require ./search_results_controller
class window.App.SearchResultsOrdersController extends App.SearchResultsController

  model: "Order"
  templatePath: "manage/views/orders/line"

  constructor: ->
    super
    new App.LinesCellTooltipController {el: @el}
    new App.UserCellTooltipController {el: @el}
    new App.OrdersApproveController {el: @el}
    new App.ContractsRejectController {el: @el, async: true, callback: @orderRejected}

  fetchRelated: (orders)=>
    @fetchUsers(orders).then => @fetchReservations(orders)

  fetchRecords: (page)=>
    App.Order.ajaxFetch
      data: $.param
        page: page
        search_term: @searchTerm
        disable_total_count: true
        status: ["approved", "submitted", "rejected"]

  fetchUsers: (orders)=>
    ids = _.uniq _.map orders, (r)-> r.user_id
    return $.when() unless ids.length
    App.User.ajaxFetch
      data: $.param
        ids: ids
        paginate: false
    .done (data)=>
      users = (App.User.find datum.id for datum in data)
      App.User.fetchDelegators users

  fetchReservations: (orders)=>
    ids = _.flatten _.map orders, (r)-> r.id
    return $.when() unless ids.length
    App.Reservation.ajaxFetch
      data: $.param
        order_ids: ids
