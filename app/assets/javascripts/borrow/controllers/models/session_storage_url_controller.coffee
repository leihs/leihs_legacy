setUrlParams = window.Packs.application.setUrlParams

class window.App.SessionStorageUrlController extends Spine.Controller

  events:
    "click": "setSessionStorageParam"

  setSessionStorageParam: (e) =>
    return if e.target.id == "start"
    if sessionStorage.length > 0
      e.preventDefault()
      href = @getHref($ e.target)
      return unless href and href.length
      window.location = setUrlParams(href, { session_storage: true })

  getHref: (el) =>
    if el.tagName != "A"
      $(el).closest("[href]").attr("href")
    else
      $(el).attr("href")


  @addSessionStorageToUrl: =>
    href = setUrlParams(window.location.href, { session_storage: true })
    history.replaceState(null, document.title, href)

  @removeSessionStorageFromUrl: =>
    href = setUrlParams(window.location.href, { session_storage: null })
    history.replaceState(null, document.title, href)
