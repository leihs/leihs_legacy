class window.App.SessionStorageUrlController extends Spine.Controller

  events:
    "click": "setSessionStorageParam"

  setSessionStorageParam: (e) =>
    return if e.target.id == "start"
    if sessionStorage.length > 0
      e.preventDefault()
      window.location = @getHref($ e.target) + "&session_storage=true"

  getHref: (el) =>
    if el.tagName != "A"
      $(el).closest("[href]").attr("href")
    else
      $(el).attr("href")

  @addSessionStorageToUrl: =>
    unless _.string.contains window.location.href, "&session_storage=true"
      href = String(window.location.href) + "&session_storage=true"
      history.replaceState(null, document.title, href)

  @removeSessionStorageFromUrl: =>
    href = String(window.location.href).replace("&session_storage=true","")
    history.replaceState(null, document.title, href)
