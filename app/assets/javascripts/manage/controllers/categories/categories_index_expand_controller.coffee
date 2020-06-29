class window.App.CategoriesIndexExpandController extends Spine.Controller

  events:
    "click [data-type='expander']": "toggle"

  openAll: (e, ctx = @el) =>
    openFn = @open
    ctx.find("[data-type='expander']").each -> openFn($(@), true)

  closeAll: (e) =>
    closeFn = @close
    @el.find("[data-type='expander']").each ->
      target = $(@)
      return if target.data("_expanded") is false
      closeFn(target)

  toggle: (e) =>
    target = $ e.currentTarget
    if target.data("_expanded")? and target.data("_expanded") == true
      @close target
    else
      @open target

  open: (target, recurseChildren) =>
    target.data "_expanded", true
    target.find(".arrow").removeClass("down right").addClass("down")
    line = target.closest("[data-id]")

    if line.data("childrenContainer")?
      childrenContainer = line.data "childrenContainer"
    else
      children = _(App.Category.find(line.data "id").children()).sortBy (c)=> c.name
      childrenContainer = $("<div class='group-of-lines level-padding'></div>")
      childrenContainer.append App.Render "manage/views/categories/line", children
      line.data "childrenContainer", childrenContainer

    line.after childrenContainer
    @openAll(null, childrenContainer) if recurseChildren

  close: (target) =>
    target.data "_expanded", false
    target.find(".arrow").removeClass("down right").addClass("right")
    line = target.closest("[data-id]")

    childrenContainer = line.next()
    childrenContainer.detach()
