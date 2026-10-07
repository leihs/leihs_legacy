#= require ./search_results_controller
class window.App.SearchResultsModelsController extends App.SearchResultsController

  model: "Model"
  templatePath: "manage/views/models/line"
  type: "model"

  constructor: ->
    super
    new App.TimeLineController {el: @el}

  fetchRelated: (models)=> @fetchAvailability(models)

  fetchRecords: (page)=>
    App[@model].ajaxFetch
      data: $.param
        search_term: @searchTerm
        type: @type
        page: page
        disable_total_count: true

  fetchAvailability: (models)=>
    ids = _.map models, (m)-> m.id
    return $.when() unless ids.length
    App.Availability.ajaxFetch
      url: App.Availability.url()+"/in_stock"
      data: $.param
        model_ids: ids
