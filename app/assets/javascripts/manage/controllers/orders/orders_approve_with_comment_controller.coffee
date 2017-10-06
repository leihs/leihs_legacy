class window.App.OrdersApproveWithCommentController extends Spine.Controller

  elements: 
    "#comment": "comment"

  constructor: (options)->
    @trigger = options.trigger
    @order = options.order
    tmpl = App.Render "manage/views/orders/approve_with_comment_modal", @order
    @modal = new App.Modal(tmpl)
    @el = @modal.el
    super
    new App.OrdersApproveController {el: @el, done: @approved, comment: => @comment.val()}

  approved: =>
    window.location = "/manage/#{App.InventoryPool.current.id}/daily?flash[success]=#{_jed('Order approved')}"
