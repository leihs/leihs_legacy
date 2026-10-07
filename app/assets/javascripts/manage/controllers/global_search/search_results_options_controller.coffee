#= require ./search_results_controller
class window.App.SearchResultsOptionsController extends App.SearchResultsController

  model: "Option"
  templatePath: "manage/views/options/line"

  constructor: ->
    super
    new App.TimeLineController {el: @el}

  fetchRecords: (page)=>
    App.Option.ajaxFetch
      data: $.param
        search_term: @searchTerm
        page: page
        disable_total_count: true
