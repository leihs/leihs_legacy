(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React

  window.Inventory = window.createReactClass({
    propTypes: {
    },

    _surround(string) {
      return ' ' + string + ' '
    },

    _isLendingManager() {
      return this.props.lending_manager
    },

    _csvImportUrl() {
      return this.props.csv_import_url
    },

    _csvExportUrl() {
      return this.props.csv_export_url
    },

    _excelExportUrl() {
      return this.props.excel_export_url
    },

    _createModelUrl() {
      return this.props.create_model_url
    },

    _createItemUrl() {
      return this.props.create_item_url
    },

    _createOptionUrl() {
      return this.props.create_option_url
    },

    _createSoftwareUrl() {
      return this.props.create_software_url
    },

    _createLicenseUrl() {
      return this.props.create_license_url
    },

    _renderCsvImport() {

      if(!this._isLendingManager()) {
        return null
      }

      return (
        <a className='button white' href={this._csvImportUrl()}>
          <i className='fa fa-table vertical-align-middle'></i>
          {this._surround(_jed('CSV import'))}
        </a>
      )

    },


    _renderDropdown() {

      if(!this._isLendingManager()) {
        return null
      }

      return (
        <div className='dropdown-holder inline-block'>
           <div className='button white dropdown-toggle'>
              {this._surround(_jed('Add inventory'))}
              <div className='arrow down'></div>
           </div>
           <ul className='dropdown right' style={{display: 'none'}}>
              <li>
                 <a className='dropdown-item' href={this._createModelUrl()}>
                   {this._surround(_jed('Model'))}
                 </a>
              </li>
              <li>
                 <a className='dropdown-item' href={this._createItemUrl()}>
                   {this._surround(_jed('Item'))}
                 </a>
              </li>
              <li>
                 <a className='dropdown-item' href={this._createOptionUrl()}>
                   {this._surround(_jed('Option'))}
                 </a>
              </li>
              <li>
                 <a className='dropdown-item' href={this._createSoftwareUrl()}>
                   {this._surround(_jed('Software'))}
                 </a>
              </li>
              <li>
                 <a className='dropdown-item' href={this._createLicenseUrl()}>
                   {this._surround(_jed('Software License'))}
                 </a>
              </li>
           </ul>
        </div>
      )
    },

    _csvExportUrlWithParams() {
      return this._csvExportUrl() + '?' + $.param(this._prepareParams())
    },

    _excelExportUrlWithParams() {
      return this._excelExportUrl() + '?' + $.param(this._prepareParams())
    },

    _renderActions() {

      return (

        <div className='text-align-right'>
          {this._renderCsvImport()}
           <span> </span>
           <div className='dropdown-holder inline-block'>
              <div className='button white dropdown-toggle'>
                 <i className='fa fa-table vertical-align-middle'></i>
                   {this._surround(_jed('Export'))}
                 <div className='arrow down'></div>
              </div>
              <ul className='dropdown right'>
                 <li>
                    <a className='dropdown-item' href={this._csvExportUrlWithParams()} id='csv-export' target='_blank'>
                      {this._surround(_jed('CSV'))}
                    </a>
                 </li>
                 <li>
                    <a className='dropdown-item' href={this._excelExportUrlWithParams()} id='excel-export' target='_blank'>
                      {this._surround(_jed('Excel'))}
                    </a>
                 </li>
              </ul>
           </div>
           <span> </span>
           {this._renderDropdown()}
        </div>
      )
    },


    _renderHeader() {
      return (

        <div className='margin-top-l padding-horizontal-m'>
           <div className='row'>
              <div className='col1of3'>
                 <h1 className='headline-xl'>{_jed('List of Inventory')}</h1>
              </div>
              <div className='col2of3'>
                {this._renderActions()}
              </div>
           </div>
        </div>
      )
    },

    _onSubTabClick(event, config) {
      event.preventDefault()
      this.setState({tabConfig: config}, this._reloadList)
    },


    _renderSubTab(label, value) {

      var className = 'inline-tab-item'
      if(this.state.tabConfig.type == value.type && this.state.tabConfig.packages == value.packages) {
        className = 'active ' + className
      }

      return (
        <a onClick={(event) => this._onSubTabClick(event, value)} className={className} data-packages={value.packages} data-type={value.type}>
          {label}
        </a>
      )
    },

    _renderSubTabs() {
      return (
        <div className='inline-tab-navigation' id='list-tabs'>
          {this._renderSubTab(_jed('All'), {})}
          {this._renderSubTab(_jed('Models'), {type: 'item', packages: 'false'})}
          {this._renderSubTab(_jed('Packages'), {type: 'item', packages: 'true'})}
          {this._renderSubTab(_jed('Options'), {type: 'option'})}
          {this._renderSubTab(_jed('Software'), {type: 'license'})}
        </div>
      )
    },

    _writeInventoryFilter() {

      var toWrite = {
        selectedTab: this.state.selectedTab,
        retired: this.state.retired,
        used: this.state.used,
        is_borrowable: this.state.is_borrowable,
        responsible_inventory_pool_id: this.state.responsible_inventory_pool_id,
        search_term: this.state.search_term,
        owned: this.state.owned,
        in_stock: this.state.in_stock,
        incomplete: this.state.incomplete,
        broken: this.state.broken,
        tabConfig: this.state.tabConfig,
        before_last_check: this.state.before_last_check,
      }

      window.sessionStorage.inventoryFilter = JSON.stringify(toWrite)
    },

    getInitialState() {

      var inventoryFilterJson = window.sessionStorage.inventoryFilter
      var inventoryFilter = null
      if(inventoryFilterJson) {
        try {
          inventoryFilter = JSON.parse(inventoryFilterJson)
        } catch(exception) {

        }
      }

      var filterReset = URI.parseQuery(window.location.search).filters == 'reset'

      if(inventoryFilter && !filterReset) {

        return {
          selectedTab: inventoryFilter.selectedTab,
          retired: inventoryFilter.retired,
          used: inventoryFilter.used,
          is_borrowable: inventoryFilter.is_borrowable,
          responsible_inventory_pool_id: inventoryFilter.responsible_inventory_pool_id,
          search_term: inventoryFilter.search_term,
          owned: inventoryFilter.owned,
          in_stock: inventoryFilter.in_stock,
          incomplete: inventoryFilter.incomplete,
          broken: inventoryFilter.broken,
          tabConfig: inventoryFilter.tabConfig,
          before_last_check: inventoryFilter.before_last_check,

          inventory: [],
          pagination: null,

          loading: true,
          openModels: {},
          openItems: {},

          showCategories: false,
          categoriesTerm: '',
          categoriesPath: [],
          categories: null,
          categoryLinks: null,
          searchMode: false

        }

      } else {


        return {
          selectedTab: null,
          retired: 'false',
          used: '',
          is_borrowable: '',
          responsible_inventory_pool_id: '',
          search_term: '',
          owned: false,
          in_stock: false,
          incomplete: false,
          broken: false,
          tabConfig: {},
          before_last_check: '',

          inventory: [],
          pagination: null,

          loading: true,
          openModels: {},
          openItems: {},

          showCategories: false,
          categoriesTerm: '',
          categoriesPath: [],
          categories: null,
          categoryLinks: null,
          searchMode: false

        }
      }



    },

    currentRequest: 0,

    _selectionFromState(name) {
      return (this.state[name] == '' ? null : this.state[name])
    },

    _checkboxFromState(name) {
      return (this.state[name] ? '1' : null)
    },


    _prepareParams() {

      var params = {}

      params.search_term = this.state.search_term
      params.type =  this.state.tabConfig.type

      if(this._currentCategory()) {
        params.category_id = this._currentCategory().id
      }

      if(params.type != 'option') {

        if(this._showSelectsOtherThanUsed()) {
          params.retired = this._selectionFromState('retired')
          params.is_borrowable =  this._selectionFromState('is_borrowable')
          params.responsible_inventory_pool_id =  this._selectionFromState('responsible_inventory_pool_id')
        }

        if(!this._hideUsedSelect()) {
          params.used = this._selectionFromState('used')
        }

        if(!this._hideCheckboxes()) {
          params.owned =  this._checkboxFromState('owned')
          params.in_stock =  this._checkboxFromState('in_stock')
          params.incomplete =  this._checkboxFromState('incomplete')
          params.broken =  this._checkboxFromState('broken')
        }

        params.packages =  this.state.tabConfig.packages
        params.before_last_check = (this.state.before_last_check != '' ? this.state.before_last_check : null)


      }

      var result = {}
      _.each(params, (value, key) => {
        if(value) {
          result[key] = value
        }
      })

      return result
    },

    _onSearchChange(event) {
      event.preventDefault()
      this.setState({search_term: event.target.value}, this._reloadList)
    },


    _onCheckboxChange(event, attribute) {
      // NOTE: Never preveent default for checkboxes.
      this.state[attribute] = event.target.checked
      this.setState(this.state, this._reloadList)
    },


    _inventoryParams(page) {
      return _.extend(
        this._prepareParams(),
        {
          page: page,
          include_package_models: true,
          sort: 'name',
          order: 'ASC'
        }
      )
    },

    _fetchInventory(page, callback) {

      App.Inventory.fetch(
        this._inventoryParams(page)
      ).done((data, status, xhr) => {

        var pagination = JSON.parse(xhr.getResponseHeader('X-Pagination'))

        var inventoryPage = data.map((datum) => {
          return new App.Inventory.findOrCreate(datum)
        })

        // var inventory = this.state.inventory
        // inventory[page - 1] = inventoryPage


        callback(page, pagination, inventoryPage)

        // this.setState({
        //   pagination: pagination,
        //   inventory: inventory
        // }, () => {
        //   callback(page, pagination)
        // })

      })

    },

    componentDidMount() {
      new App.TimeLineController({el: $('#inventory')})
      this._reloadList()
    },

    _flushLocalCache() {
      // NOTE: If you dont do this, then you perhaps get items for a model,
      // which are not in sync with the currently selected filter, but
      // the result of an earlier selected filter.

      _.each(
        [App.Item, App.License, App.Model, App.Software, App.Option],
        (e) => e.deleteAll()
      )
    },

    _reloadList() {

      this._flushLocalCache()

      this._writeInventoryFilter()
      this.setState({
        inventory: [],
        loading: true,
        openModels: {},
        openItems: {}
      }, () => {
        this.currentRequest++
        this._fetchNextPage(1, this.currentRequest)
      })
    },

    _isPaginationNotFinished(pagination) {
      return pagination.offset + pagination.per_page < pagination.total_count
    },

    _checkForNextFetch(page, request, pagination, inventoryPage) {


      var inventory = this.state.inventory
      inventory[page - 1] = inventoryPage

      this.setState({
        loading: false,
        inventory: inventory,
        pagination: pagination
      }, () =>{

        if(this._isPaginationNotFinished(pagination)) {
          this._fetchNextPage(page + 1, request)
        }
      })



    },

    _fetchNextPage(page, request) {
      if(request != this.currentRequest) return
      this._fetchInventory(page, (page, pagination, inventoryPage) => {
        if(request != this.currentRequest) return
        this._fetchAvailability(page, inventoryPage, (page) => {
          if(request != this.currentRequest) return
          this._fetchItems(page, inventoryPage, request, (page) => {
            if(request != this.currentRequest) return
            this._fetchLicenses(page, inventoryPage, request, (page) => {
              if(request != this.currentRequest) return
              this._checkForNextFetch(page, request, pagination, inventoryPage)
            })
          })
        })
      })
    },

    _fetchLicenses(page, inventoryPage, request, callback) {
      var software = _.filter(inventoryPage, (i) => i.constructor.className == 'Software')
      var ids = _.map(software, (s) => s.id)
      if(!ids.length > 0) {
        callback(page)
      } else {
        App.License.ajaxFetch({
          data: $.param(
            $.extend(
              this._prepareParams(),
              {
                model_ids: ids,
                paginate: false,
                search_term: this.state.search_term,
                all: true
              }
            )
          )
        }).done((data) => {

          if(request != this.currentRequest) return

          var licenses = data.map((d) => {
            return App.License.find(d.id)
          })

          var packages = _.filter(licenses, (i) => {
            return i.software().is_package
          })

          var children = _.flatten(
            packages.map((p) => p.children().all())
          )

          var modelIds = children.map((c) => c.model_id)

          if(modelIds.length == 0) {
            callback(page)
            return
          }

          App.Software.ajaxFetch({
            data: $.param({
              ids: modelIds,
              paginate: false,
              include_package_models: true
            })
          }).done(() => {

            callback(page)
          })
        })
      }
    },

    _fetchItems(page, inventoryPage, request, callback) {
      var models = _.filter(inventoryPage, (i) => i.constructor.className == 'Model')
      var ids = _.map(models, (m) => m.id)
      if(!ids.length > 0) {
        callback(page)
      } else {
        App.Item.ajaxFetch({
          data: $.param(
            $.extend(
              this._prepareParams(),
              {
                model_ids: ids,
                paginate: false,
                search_term: this.state.search_term,
                all: true
              }
            )
          )
        }).done((data) => {

          if(request != this.currentRequest) return

          var items = data.map((d) => {
            return App.Item.find(d.id)
          })

          var packages = _.filter(items, (i) => {
            return i.model().is_package
          })

          var children = _.flatten(
            packages.map((p) => p.children().all())
          )

          var modelIds = children.map((c) => c.model_id)

          if(modelIds.length == 0) {
            callback(page)
            return
          }

          App.Model.ajaxFetch({
            data: $.param({
              ids: modelIds,
              paginate: false,
              include_package_models: true
            })
          }).done(() => {

            callback(page)
          })

        })
      }
    },

    _fetchAvailability(page, inventoryPage, callback) {
      var models = _.filter(inventoryPage, (i) => _.contains(['Model', 'Software'], i.constructor.className))
      var ids = _.map(models, (m) => m.id)
      if(!ids.length > 0) {
        callback(page)
      } else {
        App.Availability.ajaxFetch({
          url: App.Availability.url() + '/in_stock',
          data: $.param({
            model_ids: ids
          })
        }).done(() => {
          callback(page)
        })
      }
    },

    _toggleCategories(event) {
      event.preventDefault()
      this.setState({
        showCategories: !this.state.showCategories,
        categoriesTerm: '',
        categoriesPath: [],
        searchMode: false
      }, this._reloadList)
      this._loadCategories()
    },

    _loadCategories() {
      App.Category.ajaxFetch().done((data) => {
        this.setState({categories: data.map((d) => App.Category.find(d.id))})
      })
      App.CategoryLink.ajaxFetch().done((data) => {
        this.setState({categoryLinks: data.map((d) => App.CategoryLink.find(d.id))})
      })
    },

    _renderToggleAndSearch() {

      var showCategories = true
      if(showCategories) {
        return (
          <div className='row'>
            <div className='col1of6 padding-right-xs'>
              <button onClick={this._toggleCategories} className='button inset width-full height-full no-padding text-align-center' id='categories-toggle'>
                <i className='fa fa-reorder vertical-align-middle'></i>
              </button>
            </div>
            <div className='col5of6'>
              <input value={this.state.search_term} onChange={this._onSearchChange} autoComplete='off' className='width-full' id='list-search' name='input' placeholder={_jed('Search...')} type='text' />
            </div>
          </div>
        )
      } else {
        return (
          <div className='row'>
            <div>
              <input value={this.state.search_term} onChange={this._onSearchChange} autoComplete='off' className='width-full' id='list-search' name='input' placeholder={_jed('Search...')} type='text' />
            </div>
          </div>
        )
      }


    },


    _filteredCategories(term) {
      return _.filter(
        App.Category.all(),
        (c) => c.name.match(RegExp(term, 'i'))
      )
    },

    _currentCategory() {
      if(this.state.categoriesPath.length == 0) {
        return null
      } else {
        return _.last(this.state.categoriesPath)
      }
    },

    _categoriesForPath() {
      return this._currentCategory().children()
    },

    _rootCategories() {
      return App.Category.roots()
    },

    _categoriesToRender() {

      if(this.state.searchMode) {
        return this._filteredCategories(this.state.categoriesTerm)
      } else if(this.state.categoriesPath.length > 0) {
        return this._categoriesForPath()
      } else {
        return this._rootCategories()
      }

    },

    _onCategoryLine(event, category) {
      event.preventDefault()
      this.setState(
        {
          categoriesPath: this.state.categoriesPath.concat(category),
          searchMode: false
        },
        this._reloadList
      )
    },

    _renderCategoryLine(c) {
      return (
        <a onClick={(e) => this._onCategoryLine(e, c)} key={'category_' + c.id} className='links black row focus-hover-thin font-size-m padding-horizontal-s padding-vertical-xs round-border-on-hover' data-id={c.id} data-type='category-filter'>
          {c.name}
        </a>
      )
    },

    _renderCategoriesLines() {

      return this._categoriesToRender().map((c) => {
        return this._renderCategoryLine(c)
      })
    },

    _renderCategoriesResult() {

      return (
        <div className='row padding-bottom-s' id='category-list'>
          {this._renderCategoriesLines()}
        </div>
      )

    },

    _renderCategoriesContent() {

      if(this.state.categories && this.state.categoryLinks) {

        return this._renderCategoriesResult()

        // <img className='margin-horziontal-auto margin-top-xxl margin-bottom-xxl' src='/assets/loading-4eebf3d6e9139e863f2be8c14cad4638df21bf050cea16117739b3431837ee0a.gif' />


      } else {
        return (
          <div className='row padding-bottom-s' id='category-list'>
            <div className='height-xs'></div>
            <div className='loading-bg'></div>
          </div>

        )
      }

    },

    _onCategoriesTerm(event) {
      event.preventDefault()
      this.setState(
        {
          categoriesTerm: event.target.value,
          categoriesPath: [],
          searchMode: event.target.value.length > 0
        },
        this._reloadList
      )

    },

    _onParentClick(event) {
      event.preventDefault()
      this.setState(
        {
          categoriesPath: _.first(this.state.categoriesPath, this.state.categoriesPath.length - 1),
          searchMode: false
        },
        this._reloadList
      )

    },

    _onRootClick(event) {
      event.preventDefault()
      this.setState(
        {
          categoriesPath: [_.first(this.state.categoriesPath)],
          searchMode: false
        },
        this._reloadList
      )

    },

    _renderRootCategoryContent() {
      if(this.state.categoriesPath.length > 1 && !this.state.searchMode) {
        var c = this.state.categoriesPath[0]
        return (
          <a onClick={this._onRootClick} className='emboss links black row focus-hover-thin font-size-m padding-horizontal-s padding-vertical-xs round-border-on-hover' data-id={c.id} data-type='category-root'>
            <strong>{c.name}</strong>
          </a>

        )

      } else {
        return null
      }
    },

    _renderRootCategory() {
      return (
        <div id='category-root'>
          {this._renderRootCategoryContent()}
        </div>
      )
    },


    _renderCurrentCategoryContent() {
      if(this.state.categoriesPath.length > 0 && !this.state.searchMode) {
        var c = this._currentCategory()
        return (
          <a onClick={this._onParentClick} className='emboss links black row focus-hover-thin font-size-m padding-horizontal-s padding-vertical-xs round-border-on-hover' data-id={c.id} data-type='category-current'>
            <i className='arrow left'></i>
            {' '}
            {c.name}
          </a>
        )

      } else {
        return null
      }
    },

    _renderCurrentCategory() {
      return (
        <div id='category-current'>
          {this._renderCurrentCategoryContent()}
        </div>
      )
    },

    _renderCategories() {

      var classes = 'table-cell separated-top separated-right'
      if(this.state.showCategories) {
        classes += ' col1of5'
      } else {
        classes += ' hidden'
      }


      return (
        <div className={classes} id='categories'>
          <div className='row padding-inset-s'>
            <input onChange={this._onCategoriesTerm} value={this.state.categoriesTerm} autoComplete='off' className='small' id='category-search' placeholder={_jed('Search Category')} type='text' />
          </div>
          {this._renderRootCategory()}
          {this._renderCurrentCategory()}
          {this._renderCategoriesContent()}
        </div>

      )
    },


    _renderLinesTable() {

      var classes = 'table-cell list-of-lines even separated-top padding-bottom-s min-height-l'
      if(this.state.showCategories) {
        classes += ' col4of5'
      }

      return (
        <div className={classes} id='inventory'>
          {this._renderPages(this.state.inventory)}
          {this._renderPaginationLoading()}
        </div>
      )
    },


    _showSelectsOtherThanUsed() {
      return this.state.used != 'false'

    },

    _hideUsedSelect() {
      return this.state.retired != '' || this.state.is_borrowable != '' || this.state.responsible_inventory_pool_id != ''
        || this.state.owned || this.state.in_stock || this.state.incomplete || this.state.broken
    },

    _hideCheckboxes() {
      return this.state.used == 'false'
    },

    _renderFilters() {

      var formClass = 'row margin-bottom-xs'
      var formClass2 = 'col6of8'
      if(this.state.tabConfig.type == 'option') {
        formClass += ' hidden'
        formClass2 +=  ' hidden'
      }

      var checkboxesStyle = {}
      if(this._hideCheckboxes()) {
        checkboxesStyle.display = 'none'
      }

      return (
        <div className='row margin-vertical-xs padding-horizontal-s'>
          <form className={formClass} data-filter='true'>
            <div className='col1of4 padding-right-xs'>
              <InventoryFilterSelect
                hide={!this._showSelectsOtherThanUsed()}
                name={'retired'}
                onChange={(value) => this.setState({retired: value}, this._reloadList)}
                value={this.state.retired}
                values= {
                  [
                    {value: '', label: _jed('retired') + ' & ' + _jed('not retired')},
                    {value: 'true', label: _jed('retired')},
                    {value: 'false', label: _jed('not retired')},
                  ]
                }
              />
            </div>
            <div className='col1of4 padding-right-xs'>
              <InventoryFilterSelect
                hide={this._hideUsedSelect()}
                name={'used'}
                onChange={(value) => this.setState({used: value}, this._reloadList)}
                value={this.state.used}
                values= {
                  [
                    {value: '', label: _jed('used') + ' & ' + _jed('not used')},
                    {value: 'true', label: _jed('used')},
                    {value: 'false', label: _jed('not used')},
                  ]
                }
              />
            </div>
            <div className='col1of4 padding-right-xs'>
              <InventoryFilterSelect
                hide={!this._showSelectsOtherThanUsed()}
                name={'is_borrowable'}
                onChange={(value) => this.setState({is_borrowable: value}, this._reloadList)}
                value={this.state.is_borrowable}
                values= {
                  [
                    {value: '', label: _jed('borrowable') + ' & ' + _jed('unborrowable')},
                    {value: 'true', label: _jed('borrowable')},
                    {value: 'false', label: _jed('unborrowable')},
                  ]
                }
              />
            </div>
            <div className='col1of4 padding-right-xs'>
              <InventoryFilterSelect
                hide={!this._showSelectsOtherThanUsed()}
                name={'responsible_inventory_pool_id'}
                onChange={(value) => this.setState({responsible_inventory_pool_id: value}, this._reloadList)}
                value={this.state.responsible_inventory_pool_id}
                values= {
                  [
                    {value: '', label: _jed('All inventory pools')},
                  ].concat(
                    _.map(this.props.responsibles, (r) => {
                      return {value: r.id, label: r.name}
                    })
                  )
                }
              />
            </div>
          </form>
          <div className='row'>
            <div className='col2of8 padding-right-xs'>
              {this._renderToggleAndSearch()}
            </div>
            <form className={formClass2} data-filter='true'>
              <div className='row'>
                <div className='col1of5 padding-right-xs'>
                  <label className='button inset white width-full height-xxs' htmlFor='owned' style={checkboxesStyle}>
                    <input checked={this.state.owned} autoComplete='off' id='owned' name='owned' type='checkbox' onChange={(event) => this._onCheckboxChange(event, 'owned')} />
                    <span>{_jed('Owned')}</span>
                  </label>
                </div>
                <div className='col1of5 padding-right-xs'>
                  <label className='button inset white width-full height-xxs' htmlFor='in_stock' style={checkboxesStyle}>
                    <input checked={this.state.in_stock} autoComplete='off' id='in_stock' name='in_stock' type='checkbox' onChange={(event) => this._onCheckboxChange(event, 'in_stock')} />
                    <span>{_jed('In Stock')}</span>
                  </label>
                </div>
                <div className='col1of5 padding-right-xs'>
                  <label className='button inset white width-full height-xxs' htmlFor='incomplete' style={checkboxesStyle}>
                    <input checked={this.state.incomplete} autoComplete='off' id='incomplete' name='incomplete' type='checkbox' onChange={(event) => this._onCheckboxChange(event, 'incomplete')} />
                    <span>{_jed('Incomplete')}</span>
                  </label>
                </div>
                <div className='col1of5 padding-right-xs'>
                  <label className='button inset white width-full height-xxs' htmlFor='broken' style={checkboxesStyle}>
                    <input checked={this.state.broken} autoComplete='off' id='broken' name='broken' type='checkbox' onChange={(event) => this._onCheckboxChange(event, 'broken')} />
                    <span>{_jed('Broken')}</span>
                  </label>
                </div>
                <DatePickerWithInput value={this.state.before_last_check} onChange={this._onDateChange} customRenderer={this._customRenderer}/>
              </div>
            </form>
          </div>
        </div>
      )

    },

    _onDateChange(dateString) {
      this.setState({before_last_check: dateString}, this._reloadList)

    },

    _customRenderer(arguments) {
      return (
        <div className='col1of5 padding-right-xs'>
          <label className='row'>
          <input value={arguments.value} onChange={arguments.onChange} onFocus={arguments.onFocus} autoComplete='off' className='has-addon hasDatepicker' name='before_last_check' placeholder='Inventur vor' type='text' id='dp1509973221981' />
          <span className='addon' onClick={arguments.onFocus}>
            <i className='fa fa-calendar'></i>
          </span>
          {arguments.renderPicker()}
          </label>
        </div>

      )

    },

    _renderLoadingOrNothing(child) {

      var classes = 'table-cell list-of-lines even separated-top padding-bottom-s min-height-l'
      if(this.state.showCategories) {
        classes += ' col4of5'
      }

      return (
        <div className={classes} id='inventory'>
          <div className='height-s'></div>
          {child}
          <div className='height-s'></div>
        </div>
      )


    },

    _renderResultLoading() {
      return this._renderLoadingOrNothing(
        <img className='margin-horziontal-auto margin-top-xxl margin-bottom-xxl' src='/assets/loading-4eebf3d6e9139e863f2be8c14cad4638df21bf050cea16117739b3431837ee0a.gif' />
      )
    },

    _renderResultNothingFound() {
      return this._renderLoadingOrNothing(
        <h3 className='headline-s light padding-inset-xl text-align-center'>
          No entries found
        </h3>
      )
    },


    _itemCount(model) {
      return this._modelItems(model).count()
    },

    _isModelOpen(model) {
      return (this.state.openModels[model.id] ? true : false)
    },

    _isItemOpen(item) {
      return (this.state.openItems[item.id] ? true : false)
    },

    _renderArrow(model) {

      if(this._itemCount(model) == 0) {
        return null
      } else if(this._isModelOpen(model)) {
        return (
          <i className='arrow down'></i>
        )
      } else {
        return (
          <i className='arrow right'></i>
        )
      }
    },

    _onToggleModel(event, model) {

      var openModels = this.state.openModels
      if(this._isModelOpen(model)) {
        delete openModels[model.id]
      } else {
        openModels[model.id] = model
      }
      this.setState({openModels: openModels})

    },

    _onToggleItem(event, item) {

      var openItems = this.state.openItems
      if(this._isItemOpen(item)) {
        delete openItems[item.id]
      } else {
        openItems[item.id] = item
      }
      this.setState({openItems: openItems})

    },

    _renderModelName(model) {
      return model.name()
    },


    _renderModelPackage(model) {
      if(!model.is_package) {
        return null
      }

      return (
        <div className='grey-text'>{_jed('Package')}</div>
      )
    },

    _modelDeleteLink(model) {
      return App.Model.url() + '/' + model.id
    },

    _renderModelDelete(model) {
      return (
        <li>
          <a className='dropdown-item red' data-method='delete' href={this._modelDeleteLink(model)}>
            <i className='fa fa-trash'></i>
            {_jed('Delete')}
          </a>
        </li>
      )


    },

    _renderModelEdit(model) {

      var editLabel = _jed('Edit Model')
      if(model.constructor.className == 'Software') {
        editLabel = _jed('Edit Software')
      }


      if(this._hasEditRights(model)) {
        return (
          <div className='multibutton width-full text-align-right'>
            <a className='button white text-ellipsis col4of5 negative-margin-right-xxs' href={this._modelEditLink(model)} title={editLabel}>
              {editLabel}
            </a>
            <div className='dropdown-holder inline-block col1of5'>
              <div className='button white dropdown-toggle width-full no-padding text-align-center'>
                <div className='arrow down'></div>
              </div>
              <ul className='dropdown right'>
                <li>
                  <a className='dropdown-item' data-model-id={model.id} data-open-time-line=''>
                  <i className='fa fa-align-left'></i>
                    {_jed('Timeline')}
                  </a>
                </li>
                {this._renderModelDelete(model)}
              </ul>
            </div>
          </div>
        )
      } else {
        return (
          <a className='button white text-ellipsis' data-model-id={model.id} data-open-time-line>
            <i className='fa fa-align-left'></i>
            {_jed('Timeline')}
          </a>
        )
      }


    },


    _renderModelLine(model) {

      var dataType = model.constructor.className.toLowerCase()

      return (
        <div key={'model_line_' + model.id} className='line row focus-hover-thin' data-id={model.id} data-is_package='true' data-type={dataType}>
          <div className='col1of5 line-col'>
            <div className='row'>
              <div className='col1of2'>
                <button onClick={(event) => this._onToggleModel(event, model)} className='button inset small width-full' data-type='inventory-expander' title='Packages'>
                  {this._renderArrow(model)}
                  {' '}
                  <span>{this._itemCount(model)}</span>
                </button>
              </div>
              <div className='col1of2 text-align-center height-xxs'>
                <div className='table'>
                  <div className='table-row'>
                    <div className='table-cell vertical-align-middle'>
                      <img className='max-width-xxs max-height-xxs' src={this._modelImageUrl(model)} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className='col2of5 line-col text-align-left'>
            {this._renderModelPackage(model)}
            <strong className='test-fix-timeline'>
              {this._renderModelName(model)}
            </strong>
          </div>
          <div className='col1of5 line-col text-align-center'>
            <span title={_jed('in stock')}>{model.availability().in_stock}</span>
            /
            <span title={_jed('rentable')}>{model.availability().total_rentable}</span>
          </div>
          <div className='col1of5 line-col line-actions padding-right-xs'>
            {this._renderModelEdit(model)}
          </div>
        </div>
      )
    },

    _renderOptionEdit(model) {

      if(!this._hasEditRights()) {
        return null
      }

      return (
        <a className='button white text-ellipsis' href={this._optionEditLink(model)}>
          {_jed('Edit Option')}
        </a>
      )
    },

    _renderOptionLine(model) {

      return (
        <div key={'option_line_' + model.id} className='line row focus-hover-thin' data-id={model.id} data-type='option'>
          <div className='col1of5 line-col text-align-center'>{model.inventory_code}</div>
          <div className='col2of5 line-col text-align-left'>
            <strong className='test-fix-timeline'>{model.name()}</strong>
          </div>
          <div className='col1of5 line-col text-align-center'>
            {accounting.formatMoney(model.price)}
          </div>
          <div className='col1of5 line-col line-actions padding-right-xs'>
            {this._renderOptionEdit(model)}
          </div>
        </div>
      )

      // {money(model.price)}

    },


    _itemLocation(item) {
      return item.current_location
    },

    _itemInventoryCode(item) {
      return item.inventory_code
    },

    _itemEditLink(item) {
      return App.Inventory.url().replace('/inventory', '') + '/items/' + item.id + '/edit' + '?' + $.param({return_url: App.Inventory.url()})
    },

    _itemCopyLink(item) {
      return App.Inventory.url().replace('/inventory', '') + '/items/' + item.id + '/copy' + '?' + $.param({return_url: App.Inventory.url()})
    },

    _optionEditLink(option) {
      return App.Inventory.url().replace('/inventory', '') + '/options/' + option.id + '/edit' + '?' + $.param({return_url: App.Inventory.url()})
    },

    _modelEditLink(model) {
      return App.Inventory.url().replace('/inventory', '') + '/models/' + model.id + '/edit' + '?' + $.param({return_url: App.Inventory.url()})
    },

    _modelImageUrl(model) {
      return '/models/' + model.id + '/image_thumb'
    },

    _itemEditLabel() {
      return _jed('Edit Item')
    },

    _itemCopyLabel() {
      return _jed('Copy Item')
    },

    _licenseEditLabel() {
      return _jed('Edit License')
    },

    _licenseCopyLabel() {
      return _jed('Copy License')
    },

    _appAccessRight() {
      return App.AccessRight
    },

    _appCurrentUser() {
      return App.User.current
    },

    _appCurrentUserRole() {
      return this._appCurrentUser().role
    },

    _hasEditRights() {
      return this._appAccessRight().atLeastRole(this._appCurrentUserRole(), 'lending_manager')
    },

    _renderItemEditButtons(item) {

      if(!this._hasEditRights()) {
        return null
      }

      var editLabel = this._itemEditLabel()
      var copyLabel = this._itemCopyLabel()
      if(item.type == 'License') {
        editLabel = this._licenseEditLabel()
        copyLabel = this._licenseCopyLabel()
      }

      return (
        <div className='multibutton width-full text-align-right'>
          <a className='button white text-ellipsis col4of5 negative-margin-right-xxs' href={this._itemEditLink(item)} title={editLabel}>
            {editLabel}
          </a>
          <div className='dropdown-holder inline-block col1of5'>
            <div className='button white dropdown-toggle width-full no-padding text-align-center'>
              <div className='arrow down'></div>
            </div>
            <ul className='dropdown right'>
              <li>
                <a className='dropdown-item' href={this._itemCopyLink(item)}>
                <i className='fa fa-copy'></i>
                  {copyLabel}
                </a>
              </li>
            </ul>
          </div>
        </div>
      )
    },

    _itemModel(item) {
      if(item.type == 'License') {
        return item.software()
      } else {
        return item.model()
      }
    },

    _itemIsPackage(item) {
      return this._itemModel(item).is_package
    },

    _itemChildCount(item) {
      return item.children().count()
    },

    _renderItemArrow(item) {
      if(this._itemChildCount(item) == 0) {
        return null
      }

      if(this._isItemOpen(item)) {
        return (
          <i className='arrow down'></i>
        )
      } else {
        return (
          <i className='arrow right'></i>
        )
      }
    },

    _renderItemPackageInfo(item) {

      if(!this._itemIsPackage(item)) {
        return null
      }

      return (
        <div className='row'>
          <div className='col1of2'></div>
          <div className='col1of2'>
            <button onClick={(event) => this._onToggleItem(event, item)} className='button inset small width-full' data-type='inventory-expander'>
              {this._renderItemArrow(item)}
              {' '}
              <span>{this._itemChildCount(item)}</span>
            </button>
          </div>
        </div>
      )

    },

    _itemProblems(item) {
      return item.getProblems()
    },

    _renderItemDetail(item) {
      if(item.parent_id) {
        return [
          <strong key='model_name' className='grey-text'>{this._itemModel(item).name()}</strong>
          ,
          <div key='is_package' className='row grey-text text-ellipsis width-full' title={_jed('is part of a package')}>
            {_jed('is part of a package')}
          </div>
        ]
      } else {
        return (
          <div className='row grey-text'>
            {this._itemLocation(item)}
          </div>
        )
      }

    },

    _licenseVersion(item) {
      if(item.item_version) {
        return item.itemVersion() + ', '
      } else {
        return null
      }
    },

    _licenseLocation(item) {
      if(item.current_location) {
        return item.current_location + ', '
      } else {
        return null
      }
    },

    _licenseInformation(item) {
      return item.licenseInformation()
    },

    _renderLicenseDetail(item) {

      return (
        <div className='row grey-text'>
          {this._licenseVersion(item)}
          {this._licenseLocation(item)}
          {this._licenseInformation(item)}
        </div>
      )


    },


    _renderLicenseLine(item) {

      return (
        <div key={'item_' + item.id} className='line row focus-hover-thin' data-id={item.id} data-type='license'>
          <div className='col1of5 line-col'></div>
          <div className='col2of5 line-col text-align-left'>
            <div className='row'>{this._itemInventoryCode(item)}</div>
            {this._renderLicenseDetail(item)}
          </div>
          <div className='col1of5 line-col'></div>
          <div className='col1of5 line-col line-actions padding-right-xs'>
            {this._renderItemEditButtons(item)}
          </div>
        </div>
      )


    },

    _renderItemLine(item) {

      return (
        <div key={'item_' + item.id} className='line row focus-hover-thin' data-id={item.id} data-type='item'>
          <div className='col1of5 line-col'>
            {this._renderItemPackageInfo(item)}
          </div>
          <div className='col2of5 line-col text-align-left'>
            <div className='row'>{this._itemInventoryCode(item)}</div>
            {this._renderItemDetail(item)}
          </div>
          <div className='col1of5 line-col text-align-center'>
            <strong className='darkred-text'>{this._itemProblems(item)}</strong>
          </div>
          <div className='col1of5 line-col line-actions padding-right-xs'>
            {this._renderItemEditButtons(item)}
          </div>
        </div>
      )


    },


    _renderItemOrLicenseLine(item) {

      if(item.type == 'License') {
        return this._renderLicenseLine(item)
      } else{
        return this._renderItemLine(item)
      }



    },


    _renderItemItems(item) {

      return _.flatten(
        item.children().all().map((item) => {
          return this._renderItem(item)
        })
      )


    },

    _renderItemChildren(item) {
      return (
        <div key={'item_children_' + item.id} className='group-of-lines'>
          {this._renderItemItems(item)}
        </div>
      )
    },

    _renderItem(item) {

      if(this._itemIsPackage(item) && this._isItemOpen(item)) {
        return [
          this._renderItemOrLicenseLine(item),
          this._renderItemChildren(item)
        ]
      } else {
        return this._renderItemOrLicenseLine(item)
      }


    },


    _modelItems(model) {

      if(model.constructor.className == 'Software') {
        return model.licenses()
      } else if(model.constructor.className == 'Model') {
        return model.items()
      } else {
        throw 'Unexepcted model type: ' + model.constructor.className
      }
    },

    _renderModelItems(model) {
      return _.flatten(
        this._modelItems(model).all().map((item) => {
          return this._renderItem(item)
        })
      )

    },

    _renderModelChildren(model) {
      return (
        <div key={'model_children_' + model.id} className='group-of-lines'>
          {this._renderModelItems(model)}
        </div>
      )

    },

    _renderModelWithItems(model) {

      if(model.constructor.className == 'Option') {
        return this._renderOptionLine(model)
      }


      if(this._isModelOpen(model)) {
        return [
          this._renderModelLine(model),
          this._renderModelChildren(model)
        ]
      } else {
        return this._renderModelLine(model)
      }

    },

    _renderPage(page) {
      return _.flatten(
        page.map((model) => {
          return this._renderModelWithItems(model)
        })
      )
    },

    _renderPages(pages) {
      return _.flatten(
        pages.map((page) => {
          return this._renderPage(page)
        })
      )
    },

    _renderPaginationLoading() {

      if(!this._isPaginationNotFinished(this.state.pagination)) {
        return null
      } else {
        return (
          <div className='line row focus-hover-thin'>
            <div className='height-s'></div>
            <div className='loading-bg'></div>
            <div className='height-s'></div>
          </div>
        )
      }

    },

    _renderTable() {

      return (
        <div className='table'>
          <div className='table-row'>
            {this._renderCategories()}
            {this._renderResult()}
          </div>
        </div>
      )

    },

    _renderResult() {

      if(this.state.loading) {
        return this._renderResultLoading()
      } else if(this.state.inventory[0].length == 0){
        return this._renderResultNothingFound()
      } else {
        return this._renderLinesTable()
      }


    },

    _renderContent() {

      return (
        <div className='row margin-top-l'>
          {this._renderSubTabs()}
          {this._renderFilters()}
          {this._renderTable()}
        </div>
      )

    },

    render () {
      return (

        <div className='row content-wrapper min-height-xl min-width-full straight-top'>
          {this._renderHeader()}
          {this._renderContent()}

        </div>



      )
    }
  })
})()
