class window.App.SessionStorageController extends Spine.Controller

  constructor: ->
    super
    new App.SessionStorageUrlController {el: @el.find("#breadcrumbs")}
    new App.SessionStorageUrlController {el: @el.find("#explorative-search")}

  isEmpty: => sessionStorage.length == 0

  restoreFilters: ({callback}) =>
    if sessionStorage.searchTerm
      @search.inputField.val(sessionStorage.searchTerm)
    if sessionStorage.inventoryPoolIds
      ipIds = JSON.parse(sessionStorage.inventoryPoolIds)
      if ipIds.length > 0
        @ipSelector.selectMultipleInventoryPools(ipIds)
        App.ModelsIndexIpSelectorController.activeInventoryPoolIds = ipIds
        @ipSelector.render()
    if sessionStorage.sorting
      sorting = JSON.parse(sessionStorage.sorting)
      unless _.isEmpty(sorting)
        @sorting.sort = sorting.sort
        @sorting.order = sorting.order
        @sorting.render()
    if sessionStorage.startDate
      @period.setStartDate(@getLocalizedDateFormat sessionStorage.startDate)
    if sessionStorage.endDate
      @period.setEndDate(@getLocalizedDateFormat sessionStorage.endDate)
    callback()

  clear: =>
    sessionStorage.clear()
    App.SessionStorageUrlController.removeSessionStorageFromUrl()

  update: =>
    sessionStorage.setItem(
      "inventoryPoolIds",
      JSON.stringify(@ipSelector.activeInventoryPoolIds())
    )
    sessionStorage.setItem(
      "sorting",
      JSON.stringify(@sorting.getCurrentSorting())
    )
    sessionStorage.setItem(
      "searchTerm",
      @search.inputField.val()
    )
    sessionStorage.setItem(
      "startDate",
      @formatDate @period.startDate.val()
    )
    sessionStorage.setItem(
      "endDate",
      @formatDate @period.endDate.val()
    )
    unless @isEmpty()
      App.SessionStorageUrlController.addSessionStorageToUrl()

  formatDate: (date) =>
    unless _.isEmpty(date)
      moment(date, i18n.date.L).format("DD.MM.YYYY")
    else
      date

  getLocalizedDateFormat: (date) =>
    moment(date, "DD.MM.YYYY").format(i18n.date.L)
