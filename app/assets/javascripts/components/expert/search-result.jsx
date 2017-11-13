(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.SearchResult = window.createReactClass({
    propTypes: {
    },


    _itemEditLink(item) {
      return App.Inventory.url().replace('/inventory', '') + '/items/' + item.id + '/edit'
    },


    _itemEditLabel(type) {
      switch(type) {
        case 'software':
          return 'Lizenz editieren'
        case 'model':
          return 'Gegenstand editieren'
        default:
          throw 'Not supported type: ' + type
      }
    },

    _itemColumn1ModelLabel(modelLabel, isParent) {

      var packageText = null
      if(isParent) {
        packageText = (
          <div className='grey-text'>Package</div>
        )

      }

      return (
        <div className='col1of5 line-col'>
          {packageText}
          <strong>{modelLabel}</strong>
        </div>
      )

    },

    _itemColumn1Toggle(isParent, item, childCount) {
      var toggle = <div className='col1of5 line-col'></div>
      if(isParent) {
        var _onClick = (event) => {
          this.props._toggleOpenPackage(item.id)
        }
        var direction = this._isPackageOpen(item.id) ? 'down' : 'right'
        toggle = (
          <div className='col1of5 line-col'>

            <div className='row'>
              <div className='col1of2'></div>
              <div className='col1of2'>
                <button className='button inset small width-full' data-type='inventory-expander' onClick={_onClick}>

                  <i className={'arrow ' + direction}></i>

                  <span>{' ' + childCount + ' '}</span>
                </button>
              </div>
            </div>

          </div>
        )
      }

      return toggle;
    },


    _itemColumn1(item, isParent, childCount, isChild, modelLabel) {

      if(modelLabel) {
        if(isChild) {
          return (
            <div className='col1of5 line-col'></div>
          )
        } else {
          return this._itemColumn1ModelLabel(modelLabel, isParent)
        }
      } else {
        return this._itemColumn1Toggle(isParent, item, childCount)
      }
    },


    _itemColumn23(item, isChild) {

      var to_s = null
      if(isChild) {
        to_s = <strong className='grey-text'>{item.to_s}</strong>
      }

      var text3 = null
      if(isChild) {
        text3 = 'is part of a package'
      } else {
        text3 = item.current_location
      }

      return (
        <div className='col2of5 line-col text-align-left'>
          <div className='row'>{item.inventory_code}</div>
          {to_s}
          <div className='row grey-text'>
            {text3}
          </div>
        </div>
      )

    },

    _itemColumn4(item) {

      var stati = _.compact([
        (!item.is_borrowable ? 'Nicht ausleihbar' : null),
        (item.is_broken ? 'Defekt' : null),
        (item.is_incomplete ? 'Unvollständig' : null),
        (item.retired ? 'Ausgemustert' : null)
      ])

      var status = stati.join(', ')

      return (
        <div className='col1of5 line-col text-align-center'>
          <strong className='darkred-text'>{status}</strong>
        </div>

      )


    },

    _itemColumn5(item, type) {

      return (
        <div className='col1of5 line-col line-actions padding-right-xs' style={{paddingRight: '16px'}}>

          <div className='width-full text-align-right'>
            <a className='button white text-ellipsis width-full negative-margin-right-xxs'
              href={this._itemEditLink(item)}
              title={this._itemEditLabel(type)}>
              {this._itemEditLabel(type)}
            </a>
          </div>

        </div>

      )


    },

    _searchResultItem(type, item, isParent, childCount, isChild, modelLabel) {


      return (

        <div key={'item_' + item.model_id + '_' + item.id} data-item-id={item.id} className='line row focus-hover-thin'>
          {this._itemColumn1(item, isParent, childCount, isChild, modelLabel)}
          {this._itemColumn23(item, isChild)}
          {this._itemColumn4(item)}
          {this._itemColumn5(item, type)}
        </div>


      )

    },


    _itemsForModel(type, searchResult, modelId, is_package, modelLabel) {

      if(is_package) {
        var parents = searchResult.inventory.items.filter((item) =>  {
          return item.model_id == modelId && !item.parent_id
        })

        return _.flatten(
          parents.map((parent) => {

            var children = searchResult.inventory.items.filter((item) => {
              return parent.id == item.parent_id
            })


            var result = [this._searchResultItem(type, parent, true, children.length, false, modelLabel)]
            if(this._isPackageOpen(parent.id) || modelLabel) {
              result = result.concat(children.map((child) => {
                return this._searchResultItem(type, child, false, null, true, modelLabel)
              }))
            }
            return result
          })
        )

      } else {
        return searchResult.inventory.items.filter((item) => {
          return item.model_id == modelId && !item.parent_id
        }).map((item) => {
          return this._searchResultItem(type, item, false, null, false, modelLabel)
        })
      }


    },

    _isPackageOpen(id) {

      return this.props.openPackages[id]
    },


    _isModelOpen(id) {

      return this.props.openModels[id]
    },

    _searchResultItemGroup(type, searchResult, model, is_package, modelLabel) {

      if(!this._isModelOpen(model.id) && !modelLabel) {
        return null
      }

      var itemElements = this._itemsForModel(type, searchResult, model.id, is_package, modelLabel)

      var lineClass = 'group-of-lines'
      // if(modelLabel) {
      //   lineClass = 'list-of-lines'
      // }

      if(modelLabel) {
        return itemElements;
      } else {

        return (
          <div key={'model_group_' + model.id} className={lineClass}>
            {itemElements}
          </div>
        )
      }

    },


    _availability(searchResult, data) {
      return searchResult.availabilities.find((a) => a.model_id = data.id)
    },


    _modelItemsCount(type, searchResult, modelId, is_package) {
      return searchResult.inventory.items.filter((item) => {
        return item.model_id == modelId
      }).length
    },

    _modelEditLabel(type) {
      switch(type) {
        case 'software':
          return 'Software editieren'
        case 'model':
          return 'Modell editieren'
        default:
          throw 'Not supported type: ' + type
      }

    },

    _modelEditLink(model) {
      return App.Inventory.url().replace('/inventory', '') + '/models/' + model.id + '/edit'
    },


    _searchResultModel(type, searchResult, data, is_package) {

      var arrowDirection = 'right'
      if(this._isModelOpen(data.id)) {
        arrowDirection = 'down'
      }

      var availability = this._availability(searchResult, data)

      var itemCount = this._modelItemsCount(type, searchResult, data.id, is_package)

      var downArrow = null
      var _onItemClick = null
      if(itemCount > 0) {
        downArrow = <i className={'arrow ' + arrowDirection}></i>

        _onItemClick = () => {
          this.props._toggleOpenModel(data.id)
        }


      }

      var packageText = null
      if(is_package) {
        packageText = (
          <div className='grey-text'>Package</div>
        )
      }

      // TODO accessRight? currentUserRole?
      // => check inventory_index_controller
      return (
        <div key={'model_' + data.id} className='line row focus-hover-thin' data-id='8e24ecf3-ca2e-5526-9dc1-582b6d0084fe' data-is_package='false' data-type='software'>
          <div className='col1of5 line-col'>
            <div className='row'>
              <div className='col1of2'>
                <button onClick={_onItemClick} className='button inset small width-full' title='Gegenstände'>
                  {downArrow}
                  <span>{' ' + itemCount}</span>
                </button>
              </div>
              <div className='col1of2 text-align-center height-xxs'>
                <div className='table'>
                  <div className='table-row'>
                    <div className='table-cell vertical-align-middle'>
                      <img className='max-width-xxs max-height-xxs' src={'/models/' + data.id + '/image_thumb'} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className='col2of5 line-col text-align-left'>
            {packageText}
            <strong>
              {data.label}
            </strong>
          </div>
          <div className='col1of5 line-col text-align-center'>
            <span title='auf Lager'>{availability.in_stock}</span>
            /
            <span title='verleihbar'>{availability.total_rentable}</span>
          </div>
          <div className='col1of5 line-col line-actions padding-right-xs' style={{paddingRight: '16px'}}>

            <div className='width-full text-align-right'>
              <a className='button white text-ellipsis width-full negative-margin-right-xxs'
                href={this._modelEditLink(data)}
                title={this._modelEditLabel(type)}>
                {this._modelEditLabel(type)}
              </a>
            </div>

          </div>
        </div>


      )

    },






    _searchResultLine(sr, data) {


      if(data.type == 'model') {

        var label = data.product
        if(data.version) {
          label += ' ' + data.version
        }

        var key = data.model_type.toLowerCase()

        var renderType = 'new'
        if(renderType == 'classic') {

          return [
            this._searchResultModel(
              key,
              sr,
              {
                id: data.id,
                label: label
              },
              data.model_is_package
            ),
            this._searchResultItemGroup(key, sr, data, data.model_is_package, null)
          ]

        } else {

          return [
            this._searchResultItemGroup(key, sr, data, data.model_is_package, label)

          ]
        }

      } else {

        throw 'Not implemented for options'
      }

    },



    _searchResultPage(sr) {

      return sr.inventory.data.map((entry) => {
        return this._searchResultLine(sr, entry)
      })

    },

    _searchResultLoader(searchResult) {
      if(searchResult[searchResult.length - 1].inventory.has_more) {
        // var loading = <img className='margin-horziontal-auto margin-top-xxl margin-bottom-xxl' src='/assets/loading.gif' />
        var loading = <div className='loading-bg' />
        return (
          <div key={'loader'} className='line row focus-hover-thin'>
            {loading}
          </div>
        )
      } else {
        return null
      }

    },


    _appendIfNotNull(array, item) {
      if(!item) {
        return array
      } else {
        return array.concat(item)
      }

    },

    _searchResultLines() {

      var searchResult = this.props.searchResult

      return this._appendIfNotNull(
        _.flatten(
          searchResult.map((sr, index) => {
            return this._searchResultPage(sr)
          })
        ),
        this._searchResultLoader(searchResult)
      )
    },



    _searchResult() {

      if(this.props.searchResult[0].inventory.data.length == 0) {
        return (
          <div className='table' key='result'>
            <div className='table-row'>
              <div className='table-cell list-of-lines even separated-top padding-bottom-s min-height-l' id='inventory'>
                <div className='height-s'></div>
                <h3 className='headline-s light padding-inset-xl text-align-center'>
                  {_jed('No entries found')}
                </h3>
                <div className='height-s'></div>
              </div>
            </div>
          </div>
        )
      }



      return (
        <div className='table'>
          <div className='table-row'>
            <div className='table-cell list-of-lines even separated-top padding-bottom-s min-height-l' id='inventory'>
              {this._searchResultLines()}
            </div>
          </div>
        </div>


      )

    },

    render () {
      const props = this.props

      return (
        this._searchResult()
      )
    }
  })
})()
