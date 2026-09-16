class window.App.ReservationsCourierController extends Spine.Controller

  events:
    "change [data-toggle-courier-to-pickup]": "toggleToPickup"
    "change [data-toggle-courier-to-main]": "toggleToMain"
    "change [data-select-courier-lines]": "toggleGroup"
    "click [data-toggle-courier-to-pickup]": "stopPropagation"
    "click [data-toggle-courier-to-main]": "stopPropagation"
    "click [data-select-courier-lines]": "stopPropagation"

  constructor: ->
    super
    do @syncHeaders

  stopPropagation: (e)=>
    e.stopPropagation()

  toggleToPickup: (e)=>
    @toggleCurrent(e, "to_pickup")

  toggleToMain: (e)=>
    @toggleCurrent(e, "to_main")

  toggleCurrent: (e, direction)=>
    e.stopPropagation()
    handed = e.currentTarget.checked
    currentId = $(e.currentTarget).closest("[data-id]").data("id")
    line = App.Reservation.find(currentId)
    return unless line? and @supportsCourier(line, direction)
    line.toggleCourier(direction, handed)

  toggleGroup: (e)=>
    e.stopPropagation()
    container = $(e.currentTarget).closest("[data-selected-lines-container]")
    handed = e.currentTarget.checked
    {direction, lines} = @groupCourierLines(container)
    return unless lines.length
    @syncCourierCheckboxes(lines, direction, handed)
    if lines.length == 1
      lines[0].toggleCourier(direction, handed)
      return
    requests = (line.toggleCourier(direction, handed, silent: true) for line in lines)
    $.when(requests...).always =>
      App.Reservation.trigger "update", lines[0]
      App.Reservation.trigger "refresh"

  syncCourierCheckboxes: (lines, direction, handed)=>
    selector = @selectorFor(direction)
    for line in lines
      @el.find("[data-id='#{line.id}'] #{selector}").prop("checked", handed)

  groupCourierLines: (container)=>
    {direction, inputs} = @courierInputs(container)
    ids = ($(input).closest("[data-id]").data("id") for input in inputs)
    lines = (App.Reservation.find(id) for id in ids)
    lines = (line for line in lines when line? and @supportsCourier(line, direction))
    {direction, lines}

  courierInputs: (container)=>
    pickup = container.find("[data-toggle-courier-to-pickup]")
    return {direction: "to_pickup", inputs: pickup} if pickup.length
    {direction: "to_main", inputs: container.find("[data-toggle-courier-to-main]")}

  selectorFor: (direction)=>
    if direction is "to_pickup"
      "[data-toggle-courier-to-pickup]"
    else
      "[data-toggle-courier-to-main]"

  syncHeaders: =>
    @el.find("[data-selected-lines-container]").each (i, el) =>
      @syncHeaderFor($(el))

  syncHeaderFor: (container)=>
    label = container.find("[data-courier-select-all]")
    return unless label.length
    inputs = container.find("[data-toggle-courier-to-pickup], [data-toggle-courier-to-main]")
    label.toggleClass("is-empty", inputs.length == 0)
    return unless inputs.length
    target = inputs.filter(":visible").first()
    target = inputs.first() unless target.length
    header = label.closest(".grouped-lines-header")
    checkbox = label.find("[data-select-courier-lines]")
    label.css("left", 0)
    inset = checkbox.offset().left - label.offset().left
    label.css("left", target.offset().left - header.offset().left - inset)
    label.find("[data-select-courier-lines]").prop("checked", inputs.filter(":not(:checked)").length == 0)

  supportsCourier: (line, direction)=>
    if direction is "to_pickup"
      line.showsHandedToCourierForPickup()
    else
      line.showsHandedToCourierForReturn()
