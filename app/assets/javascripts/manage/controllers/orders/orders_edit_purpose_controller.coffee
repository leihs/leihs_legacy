class window.App.OrdersEditPurposeController extends Spine.Controller

  elements:
    "textarea": "textarea"
    "#errors": "errorsContainer"

  events:
    "submit form": "submit"

  constructor: (data) ->
    @order = data.order
    @modal = new App.Modal App.Render "manage/views/orders/edit/purpose_modal", {description: @order.purpose}
    @el = @modal.el
    super

  delegateEvents: =>
    super

  submit: (e)->
    e.preventDefault()
    @order.updateAttribute("purpose", _.string.clean @textarea.val())
    @errorsContainer.addClass "hidden"
    $.ajax
      url: "/manage/#{App.InventoryPool.current.id}/orders/#{@order.id}"
      type: "PUT"
      data: {purpose: @order.purpose}
      success: (data) =>
        App.Order.trigger "refresh"
        @modal.destroy true
        @callback?()
      error: (e) =>
        @errorsContainer.removeClass "hidden"
        @errorsContainer.find("strong").text e.responseText
