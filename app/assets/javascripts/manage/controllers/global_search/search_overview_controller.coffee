class window.App.SearchOverviewController extends Spine.Controller

  elements:
    "#models": "models"
    "#software": "software"
    "#items": "items"
    "#licenses": "licenses"
    "#users": "users"
    "#delegations": "delegations"
    "#contracts": "contracts"
    "#orders": "orders"
    "#options": "options"

  constructor: ->
    super
    @previewAmount = 5
    do @searchModels
    do @searchSoftware
    do @searchItems
    do @searchLicenses
    do @searchOptions
    do @searchUsers
    do @searchDelegations
    do @searchContracts
    do @searchOrders
    new App.LatestReminderTooltipController {el: @el}
    new App.LinesCellTooltipController {el: @el}
    new App.UserCellTooltipController {el: @el}
    new App.HandOversDeleteController {el: @el}
    new App.OrdersApproveController {el: @el}
    new App.TakeBacksSendReminderController {el: @el}
    new App.OrdersRejectController {el: @el, async: true, callback: @orderRejected}
    new App.TimeLineController {el: @el}

  removeLoading: (el) ->
    el.find("[data-loading]").remove()

  searchModels: =>
    $.ajax
      url: App.Model.url(),
      type: "GET",
      dataType: "json",
      data:
        type: "model"
        per_page: @previewAmount
        search_term: @searchTerm
    .done (data, status, xhr)=> 
      models = (App.Model.addRecord new App.Model(datum) for datum in data)
      @fetchAvailability(models).done =>
        @render @models, "manage/views/models/line", models, xhr

  searchSoftware: =>
    $.ajax
      url: App.Software.url(),
      type: "GET",
      dataType: "json",
      data:
        type: "software"
        per_page: @previewAmount
        search_term: @searchTerm
    .done (data, status, xhr)=>
      software = (App.Software.addRecord new App.Software(datum) for datum in data)
      @fetchAvailability(software).done =>
        @render @software, "manage/views/software/line", software, xhr

  render: (el, templatePath, records, xhr)=>
    totalCount = JSON.parse(xhr.getResponseHeader("X-Pagination")).total_count
    @removeLoading(el)
    if records.length
      el.find(".list-of-lines").html(
        App.Render(
          templatePath,
          records,
          currentInventoryPool: App.InventoryPool.current,
          accessRight: App.AccessRight,
          currentUserRole: App.User.current.role
        )
      )
      el.removeClass("hidden")
    else
      el.addClass("hidden")
    if totalCount > @previewAmount
      el.find("[data-type='show-all']").removeClass("hidden").append $("<span class='badge margin-left-s'>#{totalCount}</span>")

  fetchAvailability: (models)=>
    ids = _.map models, (m)-> m.id
    return {done: (c)->c()} unless ids.length
    $.ajax
      url: App.Availability.url()+"/in_stock",
      type: "GET",
      dataType: "json",
      data:
        model_ids: ids
    .done (data) =>
      App.Availability.addRecord new App.Availability(datum) for datum in data


  searchItems: =>
    $.ajax
      url: App.Item.url(),
      type: "GET",
      dataType: "json",
      data:
        type: "item"
        per_page: @previewAmount
        search_term: @searchTerm
        current_inventory_pool: false
    .done (data, status, xhr)=> 
      items = (App.Item.addRecord new App.Item(datum) for datum in data)
      @fetchModels(items).done =>
        @render @items, "manage/views/items/line", items, xhr

  searchLicenses: =>
    $.ajax
      url: App.License.url(),
      type: "GET",
      dataType: "json",
      data:
        type: "license"
        per_page: @previewAmount
        search_term: @searchTerm
        current_inventory_pool: false
    .done (data, status, xhr)=>
      licenses = (App.License.addRecord new App.License(datum) for datum in data)
      @fetchModels(licenses).done (data) =>
        @render @licenses, "manage/views/licenses/line", licenses, xhr

  fetchModels:(items) =>
    ids = _.uniq _.map items, (m)-> m.model_id
    return {done: (c)->c()} unless ids.length
    $.ajax
      url: App.Model.url(),
      type: "GET",
      dataType: "json",
      data:
        ids: ids
        paginate: false
        include_package_models: true
    .done (data) =>
      App.Model.addRecord new App.Model(datum) for datum in data

  searchDelegations: =>
    $.ajax
      url: App.User.url(),
      type: "GET",
      dataType: "json",
      data:
        per_page: @previewAmount
        search_term: @searchTerm
        type: 'delegation'
    .done (data, status, xhr)=>
      delegations = (App.User.addRecord new App.User(datum) for datum in data)
      App.User.fetchDelegators delegations, =>
        @render @delegations, "manage/views/users/search_result_line", delegations, xhr

  searchUsers: =>
    $.ajax
      url: App.User.url(),
      type: "GET",
      dataType: "json",
      data:
        per_page: @previewAmount
        search_term: @searchTerm
        type: 'user'
        content_type: "application/json"
    .done (data, status, xhr)=>
      users = (App.User.addRecord new App.User(datum) for datum in data)
      @render @users, "manage/views/users/search_result_line", users, xhr

  searchContracts: =>
    $.ajax
      url: App.Contract.url(),
      type: "GET",
      dataType: "json",
      data:
        per_page: @previewAmount
        global_contracts_search: true
        search_term: @searchTerm
        status: ["open", "closed"]
    .done (data, status, xhr)=>
      contracts = (App.Contract.addRecord new App.Contract(datum) for datum in data)
      @fetchUsers(contracts, "all").done =>
        @fetchReservationsForContracts(contracts).done =>
          @render @contracts, "manage/views/contracts/line", contracts, xhr

  fetchUsers: (records, all = false) =>
    ids = _.uniq _.map records, (r)-> r.user_id
    return {done: (c)->c()} unless ids.length
    data =
      ids: ids
      paginate: false
    $.extend data, {all: true} if all == "all"
    $.ajax
      url: App.User.url(),
      type: "GET",
      dataType: "json",
      data: data
    .done (data)=>
      users = (App.User.addRecord new App.User(datum) for datum in data)
      App.User.fetchDelegators users

  fetchReservationsForContracts: (records)=>
    ids = _.flatten _.map records, (r)-> r.id
    return {done: (c)->c()} unless ids.length
    $.ajax
      url: App.Reservation.url(),
      type: "GET",
      dataType: "json",
      data:
        contract_ids: ids
        paginate: false
    .done (data) =>
      App.Reservation.addRecord new App.Reservation(datum) for datum in data

  fetchReservationsForOrders: (records)=>
    ids = _.flatten _.map records, (r)-> r.id
    return {done: (c)->c()} unless ids.length
    $.ajax
      url: App.Reservation.url(),
      type: "GET",
      dataType: "json",
      data:
        order_ids: ids
        paginate: false
    .done (data) =>
      App.Reservation.addRecord new App.Reservation(datum) for datum in data

  searchOrders: =>
    $.ajax
      url: App.Order.url(),
      type: "GET",
      dataType: "json",
      data:
        per_page: @previewAmount
        search_term: @searchTerm
        status: ["approved", "submitted", "rejected"]
    .done (data, status, xhr)=>
      orders = (App.Order.addRecord new App.Order(datum) for datum in data)
      @fetchUsers(orders, "all").done (data) =>
        @fetchReservationsForOrders(orders).done (data) =>
          @render @orders, "manage/views/orders/line", orders, xhr

  searchOptions: =>
    $.ajax
      url: App.Option.url(),
      type: "GET",
      dataType: "json",
      data:
        per_page: @previewAmount
        search_term: @searchTerm
    .done (data, status, xhr)=>
        options = (App.Option.addRecord new App.Option(datum) for datum in data)
        @render @options, "manage/views/options/line", options, xhr
