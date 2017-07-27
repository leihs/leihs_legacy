class window.App.ModelsIndexTooltipController extends Spine.Controller

  events:
    "mouseleave .line[data-id]": "leaveLine"
    "mouseenter .line[data-id]": "enterLine"

  tooltips: {}

  createTooltip: (line) =>
    new App.Tooltip
      el: line
      trackTooltip: true
      delay: [200, 100]
      trigger: 'hover'

  fetchProperties: (model_id, target) =>
    App.Property.ajaxFetch
      data: $.param
        model_ids: [model_id]
    .done =>
      return false unless App.Model.exists model_id
      return false if @tooltips[model_id]? && target.hasClass('tooltipstered')

      tooltip = @createTooltip target
      @tooltips[model_id] = tooltip
      @currentTooltip = tooltip

      if tooltip?
        model = App.Model.find(model_id)
        model.propertiesToDisplay = _.first model.properties().all(), 5
        model.amount_of_images = 1
        content = App.Render "borrow/views/models/index/tooltip", model
        tooltip.update content
        setTimeout(=>
          tooltip.show() if @currentTooltip == tooltip and @mouseOverTooltip
        , 0)

  enterLine: (e)=>
    @mouseOverTooltip = true
    @currentTargetId = $(e.currentTarget).data("id")
    _.delay (=> @stayOnLine e), 200

  stayOnLine: (e)=>
    return false if @currentTargetId != $(e.currentTarget).data("id") or !@mouseOverTooltip
    $("*:focus").blur().datepicker("hide")
    target = $(e.currentTarget)
    model_id = target.data('id')
    if App.Model.exists model_id
      unless @tooltips[model_id]? && target.hasClass('tooltipstered')
        @fetchProperties model_id, target
      else
        tooltip = @tooltips[model_id]
        @currentTooltip = tooltip

  leaveLine: (e)=>
    @mouseOverTooltip = false
