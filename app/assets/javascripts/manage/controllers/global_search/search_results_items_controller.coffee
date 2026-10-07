#= require ./search_results_controller
class window.App.SearchResultsItemsController extends App.SearchResultsController

  model: "Item"
  dependingOnModel: "Model"
  templatePath: "manage/views/items/line"
  type: "item"

  fetchRelated: (items)=> @fetchModels(items)

  fetchRecords: (page)=>
    App[@model].ajaxFetch
      data: $.param
        search_term: @searchTerm
        type: @type
        page: page
        current_inventory_pool: false
        disable_total_count: true

  fetchModels:(items) =>
    ids = _.uniq _.map items, (i)-> i.model_id
    return $.when() unless ids.length
    App[@dependingOnModel].ajaxFetch
      data: $.param
        ids: ids
        paginate: false
        include_package_models: true
