class window.App.LinesCellTooltipController extends Spine.Controller

  events:
    "mouseenter [data-type='lines-cell']": "onEnter"

  onEnter: (e)=>
    trigger = $(e.currentTarget)
    record = if trigger.closest(".line[data-type='contract']").length 
      App.Contract.findOrBuild(trigger.closest(".line[data-type='contract']").data())
    else if trigger.closest(".line[data-type='order']").length 
      App.Order.findOrBuild(trigger.closest(".line[data-type='order']").data())
    else if trigger.closest(".line[data-type='take_back']").length 
      App.Visit.findOrBuild(trigger.closest(".line[data-type='take_back']").data())
    else if trigger.closest(".line[data-type='hand_over']").length 
      App.Visit.findOrBuild(trigger.closest(".line[data-type='hand_over']").data())
    tooltip = new App.Tooltip
      el: trigger.closest(".line-col")
      content: App.Render "views/loading", {size: "micro"}
    @fetchData record, => tooltip.update App.Render "manage/views/reservations/tooltip", record

  fetchData: (record, callback)=>
    modelIds = []
    optionIds = []
    for line in record.reservations().all()
      if line.model_id?
        modelIds.push(line.model_id) unless App.Model.exists(line.model_id)?
      else if line.option_id?
        optionIds.push(line.option_id) unless App.Option.exists(line.option_id)?
    if modelIds.length > 0
      @sliceFetchModels modelIds, =>
        if optionIds.length > 0
          @sliceFetchOptions optionIds, callback
        else
          @fetchOptions(optionIds).done => do callback
    else
      @fetchModels(modelIds).done =>
        if optionIds.length > 0
          @sliceFetchOptions optionIds, callback
        else
          @fetchOptions(optionIds).done => do callback

  sliceFetchModels: (modelIds, callback) =>
    callback_after = _.after(Math.ceil(modelIds.length / 50), callback)
    _(modelIds).each_slice 50, (slice) =>
      @fetchModels(slice).done callback_after

  sliceFetchOptions: (optionIds, callback) =>
    callback_after = _.after(Math.ceil(optionIds.length / 50), callback)
    _(optionIds).each_slice 50, (slice) =>
      @fetchOptions(slice).done callback_after

  fetchModels: (ids)=>
    if ids.length
      App.Model.ajaxFetch
        data: $.param
          ids: ids
          paginate: false
    else
      {done: (c)->c()}

  fetchOptions: (ids)=>
    if ids.length
      App.Option.ajaxFetch
        data: $.param
          ids: ids
          paginate: false
    else
      {done: (c)->c()}
