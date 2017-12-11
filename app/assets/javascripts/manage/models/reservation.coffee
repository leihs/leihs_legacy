## Global

window.App.Reservation.url = => "/manage/#{App.InventoryPool.current.id}/reservations"

window.App.Reservation.createOne = (data)->
  $.post("/manage/#{App.InventoryPool.current.id}/reservations", data)
  .done (reservation)->
    App.Reservation.addRecord new App.Reservation reservation
    App.Reservation.trigger "refresh"
    App.Order.trigger "refresh"

window.App.Reservation.createForTemplate = (data)->
  $.ajax
    url: "/manage/#{App.InventoryPool.current.id}/reservations/for_template"
    data: data
    method: "POST"
    success: (reservations) ->
      records = for reservation in reservations
        App.Reservation.addRecord new App.Reservation reservation
      $.ajax
        url: App.Model.url()
        data: $.param
          template_id: data.template_id
          paginate: false
        success: (models) ->
          for model in models
            App.Model.addRecord new App.Model model
          App.Model.trigger "refresh"
          App.Reservation.trigger "refresh"
          App.Order.trigger "refresh"


window.App.Reservation.destroyMultiple = (ids)->
  App.Reservation.find(id).remove() for id in ids
  $.ajax
    url: "/manage/#{App.InventoryPool.current.id}/reservations/"
    type: "post"
    data: 
      line_ids: ids
      _method: "delete"
  .done ->
    App.Reservation.trigger "destroy", ids
    App.Order.trigger "refresh"

window.App.Reservation.changeTimeRange = (reservations, startDate, endDate)=>
  startDate = moment(startDate).format("YYYY-MM-DD") if startDate
  endDate = moment(endDate).format("YYYY-MM-DD")
  $.post "/manage/#{App.InventoryPool.current.id}/reservations/change_time_range",
    line_ids: _.map(reservations,(l)->l.id)
    start_date: startDate
    end_date: endDate
  .done =>
    for line in reservations
      data = {end_date: endDate}
      data["start_date"] = startDate if startDate
      line.refresh data
    App.Reservation.trigger "refresh"
    App.Order.trigger "refresh"

window.App.Reservation.assignOrCreate = (data)->
  $.post("/manage/#{App.InventoryPool.current.id}/reservations/assign_or_create", data)

window.App.Reservation.takeBack = (reservations, returnedQuantity)->
  $.post "/manage/#{App.InventoryPool.current.id}/reservations/take_back",
    ids: (line.id for line in reservations)
    returned_quantity: returnedQuantity

window.App.Reservation.swapUser = (reservations, userId)->
  $.post "/manage/#{App.InventoryPool.current.id}/reservations/swap_user",
    line_ids: (line.id for line in reservations)
    user_id: userId

Spine.Model.include.call App.Reservation, App.Modules.LineProblems

## Prototype

window.App.Reservation::assign = (item, callback = null)->
  $.post("/manage/#{App.InventoryPool.current.id}/reservations/#{@id}/assign", {inventory_code: item.inventory_code})
  .fail (e)=>
    msg = e.responseJSON?.message || e.responseText
    App.Flash(type: "error", message: msg)
  .done (data)=>
    @refresh data
    App.Reservation.trigger "update", @
    App.Flash
      type: "success"
      message: _jed "%s assigned to %s", [item.inventory_code, (item.model() ? item.software()).name()]
    callback?()

window.App.Reservation::removeAssignment = ->
  $.post("/manage/#{App.InventoryPool.current.id}/reservations/#{@id}/remove_assignment")
  @refresh {item_id: null}
  App.Reservation.trigger "update", @
