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
    return if e.currentTarget.disabled
    handed = e.currentTarget.checked
    currentId = $(e.currentTarget).closest("[data-id]").data("id")
    line = App.Reservation.find(currentId)
    return unless line? and @supportsCourier(line, direction)
    line.toggleCourier(direction, handed,
      onError: =>
        $(e.currentTarget).prop("checked", !handed)
        do @syncHeaders
      onSuccess: =>
        # Re-sync from model: availability re-render can wipe the optimistic
        # check before the stamp lands on the reservation.
        @syncCourierCheckboxes([line], direction, handed)
        do @syncHeaders
    )

  toggleGroup: (e)=>
    e.stopPropagation()
    return if e.currentTarget.disabled
    container = $(e.currentTarget).closest("[data-selected-lines-container]")
    handed = e.currentTarget.checked
    {direction, lines} = @groupCourierLines(container)
    return unless lines.length
    previous = for line in lines
      if direction is "to_pickup"
        line.handedToCourierForPickup()
      else
        line.handedToCourierForReturn()
    changing = []
    previousChanging = []
    for line, i in lines
      unless previous[i] is handed
        changing.push line
        previousChanging.push previous[i]
    return do @syncHeaders unless changing.length
    @syncCourierCheckboxes(changing, direction, handed)
    if changing.length == 1
      changing[0].toggleCourier(direction, handed,
        onError: =>
          @syncCourierCheckboxes(changing, direction, previousChanging[0])
          do @syncHeaders
        onSuccess: =>
          @syncCourierCheckboxes(changing, direction, handed)
          do @syncHeaders
      )
      return
    pending = changing.length
    failed = []
    for line, i in changing
      do (line, i) =>
        line.toggleCourier(direction, handed, silent: true)
          .fail =>
            failed.push line
            @syncCourierCheckboxes([line], direction, previousChanging[i])
          .always =>
            pending -= 1
            if pending is 0
              succeeded = (l for l in changing when l not in failed)
              @syncCourierCheckboxes(succeeded, direction, handed) if succeeded.length
              do @syncHeaders

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
    do @syncLineCheckboxesFromModels
    @el.find("[data-selected-lines-container]").each (i, el) =>
      @syncHeaderFor($(el))

  # Keep line checkboxes aligned with reservation stamps after #lines re-render
  # (e.g. take-back availability fetch).
  syncLineCheckboxesFromModels: =>
    @el.find("[data-toggle-courier-to-pickup], [data-toggle-courier-to-main]").each (i, el) =>
      $el = $(el)
      line = App.Reservation.find($el.closest("[data-id]").data("id"))
      return unless line?
      if $el.is("[data-toggle-courier-to-pickup]")
        $el.prop("checked", line.handedToCourierForPickup())
      else
        $el.prop("checked", line.handedToCourierForReturn())

  syncHeaderFor: (container)=>
    label = container.find("[data-courier-select-all]")
    return unless label.length
    inputs = container.find("[data-toggle-courier-to-pickup], [data-toggle-courier-to-main]")
    label.toggleClass("is-empty", inputs.length == 0)
    return unless inputs.length
    checkbox = label.find("[data-select-courier-lines]")
    checkbox.prop("checked", inputs.filter(":not(:checked)").length == 0)
    target = inputs.filter(":visible").first()
    target = inputs.first() unless target.length
    header = label.closest(".grouped-lines-header")
    labelOffset = label.offset()
    targetOffset = target.offset()
    headerOffset = header.offset()
    return unless labelOffset? and targetOffset? and headerOffset?
    label.css("left", 0)
    inset = checkbox.offset().left - label.offset().left
    label.css("left", targetOffset.left - headerOffset.left - inset)

  supportsCourier: (line, direction)=>
    if direction is "to_pickup"
      line.showsHandedToCourierForPickup()
    else
      line.showsHandedToCourierForReturn()
