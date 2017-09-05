
window.FetchInventory = {


  _fetchAvailability(xhrContext, inventory, callback) {

    var ids = inventory.data.filter((e) => e.type == 'model').map((e) => e.id)

    if(ids.length > 0) {
      var xhrKey = xhrContext.rememberXhr(
        $.ajax({
          url: App.Availability.url() + '/in_stock',
          data: $.param(
            {model_ids: ids}

          ),
          dataType: 'json'
        }).done((data) => {
          xhrContext.removeXhr(xhrKey)

          callback(inventory, data)
        })

      )

    } else {
      callback(inventory, [])

    }

  },

  _buildFieldFilter(selectedValue) {
    var field = selectedValue.field
    return [{
      id: field.id,
      value: selectedValue.value
    }].concat(
      this._buildFieldFilters(selectedValue.dependents)
    )
  },

  _buildFieldFilters(selectedValues) {

    return _.compact(_.flatten(selectedValues.map((selectedValue) => {
      return this._buildFieldFilter(selectedValue)
    })))

  },

  _fetchInventory(xhrContext, startIndex, selectedValues, callback) {
    xhrContext.cancelXhrs()

    var fieldFilters = this._buildFieldFilters(selectedValues)

    var xhrKey = xhrContext.rememberXhr(
      $.ajax({
        url: App.Inventory.url() + '/expert/index',
        data: $.extend(
            {},//this._getData(),
            {
              start_index: startIndex,
              search_term: '',
              category_id: void 0,
              include_package_models: true,
              sort: 'name',
              order: 'ASC',
              field_filters: encodeURI(JSON.stringify(fieldFilters))
            }
          ),
        dataType: 'json'

      }).done((data) => {
        xhrContext.removeXhr(xhrKey)
        this._fetchAvailability(xhrContext, data, callback)

      })
    )

  },




}
