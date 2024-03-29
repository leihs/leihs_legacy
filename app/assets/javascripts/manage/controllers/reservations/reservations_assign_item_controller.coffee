class window.App.ReservationAssignItemController extends Spine.Controller

  events:
    "focus [data-assign-item]": "searchItems"
    "submit [data-assign-item-form]": "submitAssignment"
    "click [data-remove-assignment]": "removeAssignment"

  constructor: ->
    super

  searchItems: (e)=>
    target = $ e.currentTarget
    model = App.Reservation.find(target.closest("[data-id]").data("id")).model()
    (if model.constructor == App.Model
      @fetchItems(model)
    else if model.constructor == App.Software
      @fetchLicenses(model))
    .done (data)=>
      items = ((App.Item.exists(datum.id) ? App.License.find(datum.id)) for datum in data)
      if items.length
        @setupAutocomplete(target, items)

  setupAutocomplete: (input, items)->
    return false if not input.is(":focus") or input.is(":disabled")
    input.autocomplete
      appendTo: input.closest(".line")
      source: (request, response)=>
        data = _.map items, (u)=>
          u.value = u.id
          u
        data = _.filter data, (i)->i.inventory_code.match request.term
        response data
      focus: => return false
      minLength: 0
      select: (e, ui)=> @assignItem(input, ui.item); return false
    .data("uiAutocomplete")._renderItem = (ul, item) =>
      $(App.Render "manage/views/items/autocomplete_element", item).data("value", item).appendTo(ul)
    input.autocomplete("search", "")

  fetchItemsOrLicences: (klass, model) =>
    klass.ajaxFetch
      data: $.param
        model_ids: [model.id]
        in_stock: true
        responsible_inventory_pool_id: App.InventoryPool.current.id
        retired: false
        sort_by_inventory_code: true
        per_page: 250

  fetchItems: _.partial this::fetchItemsOrLicences, App.Item
  fetchLicenses: _.partial this::fetchItemsOrLicences, App.License

  fetchWithIds: (klass, ids) =>
    return {done: (c)-> c()} unless ids.length
    klass.ajaxFetch
      data: $.param
        ids: ids

  fetchBuildings: _.partial this::fetchWithIds, App.Building

  assignItem: (input, item)=>
    input.blur()
    input.autocomplete "destroy"
    reservation = App.Reservation.find input.closest("[data-id]").data("id")
    reservation.assign item, =>
      input.val item.inventory_code
      input.prop "disabled", true
      App.LineSelectionController.add reservation.id

  removeAssignment: (e)=>
    target = $ e.currentTarget
    reservation = App.Reservation.find target.closest("[data-id]").data("id")
    do reservation.removeAssignment
    App.Flash
      type: "notice"
      message: _jed "The assignment for %s was removed", reservation.model().name()

  submitAssignment: (e)=>
    e.preventDefault()
    target = $(e.currentTarget).find("[data-assign-item]")
    reservation = App.Reservation.find target.closest("[data-id]").data("id")
    inventoryCode = target.val()
    model = reservation.model()
    spineModel = if model.constructor == App.Model
      App.Item
    else if model.constructor == App.Software
      App.License
    spineModel.ajaxFetch
      data: $.param
        inventory_code: inventoryCode
    .done (data)=>
      if data.length == 1
        @assignItem target, spineModel.find(data[0].id)
      else
        App.Flash
          type: "error"
          message: _jed "The Inventory Code %s was not found for %s", [inventoryCode, reservation.model().name()]
