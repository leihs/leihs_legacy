(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  // TODO
  // - Highlighting of current day and current selected date in picker.
  // - Make sure no SQL injections are possible.

  window.Expert = window.createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        loadingFields: 'initial',
        selectedValues: [],
        searchResult: null,
        openModels: {},
        openPackages: {}
      }
    },

    _fetchFields () {
      this.setState({loadingFields: 'loading'})
      App.Field.ajaxFetch({
        data: $.param({target_type: 'item'})
      }).done((data) => {
        this.setState({
          loadingFields: 'done',
          fields: data
        })
      })
    },

    componentDidMount () {
      this.xhrContext = XhrContext()

      Scrolling.mount(this._onScroll)

      this._fetchFields()
      this._refreshList()
    },

    componentWillUnmount () {
      // Assumption:
      // If your XHR is pending, and you go to the next page and use the browser back button, then
      // you most likely do not enter the XHR callback, which in this component means,
      // that the next page is not loaded. Thats why we explicitly cancel it.
      this.xhrContext.cancelXhrs()
      Scrollling.unmount(this._onScroll)
    },

    _onScroll () {
      this._tryLoadNext()
    },

    _updateSearchResult(inventory, availabilities) {
      var page = {
        inventory: inventory,
        availabilities: availabilities,
        items: null
      }

      var searchResult = this.state.searchResult
      if(!searchResult) {
        searchResult = [page]
      } else {

        var lastPage = searchResult[searchResult.length - 1]
        if(lastPage.inventory.start_index + lastPage.inventory.page_size == inventory.start_index) {
          searchResult = searchResult.concat(page)
        }
      }

      this.setState({
        searchResult: searchResult
      })

      this._tryLoadNext()
    },

    _tryLoadNext() {
      if(!this.xhrContext.isEmpty()) {
        return
      }

      var searchResult = this.state.searchResult
      var alreadyMoreThanNPages = searchResult && searchResult.length >= 5

      if(!Scrolling._isBottom() && alreadyMoreThanNPages) {
        return
      }

      var searchResult = this.state.searchResult
      if(!searchResult || _.last(searchResult).inventory.has_more) {
        var lastPage = _.last(searchResult)
        this._fetchInventory(lastPage.inventory.start_index + lastPage.inventory.page_size)
      }
    },

    _fetchInventory(startIndex) {
      this.setState({refresh: !this.state.refresh})
      FetchInventory._fetchInventory(this.xhrContext, startIndex, this.state.selectedValues, (inventory, data) => {
        this._updateSearchResult(inventory, data)
      })
    },

    _refreshList() {
      this._clearOpenModels()
      this._clearOpenPackages()

      this.setState(
        {
          searchResult: null
        },
        () => {
          this._fetchInventory(0)
        }
      )
    },

    _selectedValuesChanged(selectedValues) {
      this.setState(
        {selectedValues: selectedValues},
        this._refreshList
      )
    },

    _searchResultLoading() {
      // var loading = <img className='margin-horziontal-auto margin-top-xxl margin-bottom-xxl' src='/assets/loading.gif' />
      var loading = <div className='loading-bg' />
      return (
        <div className='table' key='result'>
          <div className='table-row'>
            <div className='table-cell list-of-lines even separated-top padding-bottom-s min-height-l' id='inventory'>
              <div className='height-s'></div>
              {loading}
              <div className='height-s'></div>
            </div>
          </div>
        </div>
      )
    },

    _searchResultComponent() {
      return (
        <SearchResult key='result' searchResult={this.state.searchResult}
          openModels={this.state.openModels}
          openPackages={this.state.openPackages}
          _toggleOpenPackage={this._toggleOpenPackage}
          _toggleOpenModel={this._toggleOpenModel}
        />
      )
    },

    _searchResult() {
      if(!this.state.searchResult) {
        return this._searchResultLoading()
      } else {
        return this._searchResultComponent()
      }
    },

    _loadingFields() {
      // var loading = <img className='margin-horziontal-auto margin-top-xxl margin-bottom-xxl' src='/assets/loading.gif' />
      var loading = <div className='loading-bg' />

      return (
        <div className='table'>
          <div className='table-row'>
            <div className='table-cell list-of-lines even separated-top padding-bottom-s min-height-l' id='inventory' style={{border: '0px'}}>
              <div className='height-s'></div>
              {loading}
              <div className='height-s'></div>
            </div>
          </div>
        </div>
      )
    },

    _searchMask() {
      return (
        <SearchMaskState key='select' fields={this.state.fields}
          selectedValues={this.state.selectedValues}
          parent={this}
          selectedValuesChanged={this._selectedValuesChanged}
        />
      )
    },

    _readyContent() {
      return [
        this._searchMask(),
        this._searchResult()
      ]
    },

    _content () {
      if(this.state.loadingFields != 'done') {
        return this._loadingFields()
      } else {
        return this._readyContent()
      }
    },

    _clearOpenModels() {
      this.setState({openModels: {}})
    },

    _clearOpenPackages() {
      this.setState({openPackages: {}})
    },

    _toggleOpenModel(id) {
      var openModels = this.state.openModels
      if(openModels[id]) {
        delete openModels[id]
      } else {
        openModels[id] = 'open'
      }
      this.setState({openModels: openModels})
    },

    _toggleOpenPackage(id) {
      var openPackages = this.state.openPackages
      if(openPackages[id]) {
        delete openPackages[id]
      } else {
        openPackages[id] = 'open'
      }
      this.setState({openPackages: openPackages})
    },

    render () {
      return (
        <div className='row content-wrapper min-height-xl min-width-full straight-top'>
          <TitleAndExport selectedValues={this.state.selectedValues} />
          {this._content()}
        </div>
      )
    }
  })
})()
