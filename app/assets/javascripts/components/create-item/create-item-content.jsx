(() => {

  const React = window.React

  window.CreateItemContent = window.createReactClass({
    propTypes: {
    },

    _attachInputForBarcodeScanner(){
      if (window && this.refs)
        window.reactBarcodeScannerTarget = this.refs['create-item-autocomplete']
    },
    componentDidMount() {
      this._attachInputForBarcodeScanner()
    },
    componentDidUpdate() {
      this._attachInputForBarcodeScanner()
    },


    _isItemOwner() {

      var owner = this.props.createItemProps.item.owner
      return owner.id == App.InventoryPool.current.id

    },


    _renderModelLabel(parent) {
      return parent.model.product + (parent.model.version ? ' ' + parent.model.version : '') + ' ' + parent.inventory_code

    },

    _renderPackageInfo() {
      if(this.props.createItemProps.parent) {
        var parent = this.props.createItemProps.parent
        return (
          <div className='padding-bottom-m'>
            <div className='row emboss notice text-align-center font-size-m padding-inset-s'>
              <strong>Gegenstand ist Teil eines Pakets: </strong>
              <a className='white' href={parent.edit_path}>
                {this._renderModelLabel(parent.json)}
              </a>
            </div>
          </div>
        )

      } else {
        return null
      }
    },

    _renderChildrenInfo() {

      if(this.props.createItemProps.children) {
        var children = this.props.createItemProps.children

        var childLinks = children.map(
          (child) => {
            return (
              <a key={child.json.id} className='row white' href={child.edit_path}>
                {this._renderModelLabel(child.json)}
              </a>

            )
          }
        )

        return (
          <div className='padding-bottom-m'>
            <div className='row emboss notice text-align-center font-size-m padding-inset-s'>
              <strong>Dies ist ein Paket, bestehend aus den folgenden Gegenständen: </strong>
              {childLinks}
            </div>
          </div>
        )

      } else {
        return null
      }

    },

    _renderNotOwner() {
      if(this.props.createItemProps.item && !this._isItemOwner()) {
        return (
          <div className='padding-bottom-m'>
            <div className='row emboss notice text-align-center font-size-m padding-inset-s'>
              <strong>Sie sind nicht Besitzer dieses Gegenstands: </strong>
              deshalb können Sie einige Felder nicht editieren
            </div>
          </div>
        )
      } else {
        return null
      }
    },

    _renderNotifications() {

      return (
        <div className='padding-vertical-m' id='notifications'>
          {this._renderPackageInfo()}
          {this._renderChildrenInfo()}
          {this._renderNotOwner()}
        </div>
      )

    },

    _isLicense() {
      return this.props.createItemProps.item_type == 'license'
    },

    _hasTechnicalDetail() {
      if(!this.props.createItemProps.item) {
        return false
      } else {
        return !_.isEmpty(this.props.createItemProps.item.model.technical_detail)
      }
    },

    _hasAttachments() {
      return !_.isEmpty(this.props.createItemProps.model_attachments)
    },

    _technicalDetailLines() {
      return this.props.createItemProps.item.model.technical_detail.split('\r\n')
    },

    _technicalDetailLinesWithLinks() {
      return _.filter(this._technicalDetailLines(), (line) => {
        return this._lineHasLink(line)
      })
    },

    _linkRegex() {
      return /(https?:\S*)/gi
    },

    _emailRegex() {
      return /(\S+@\S+\.\S+)/gi
    },

    _lineHasLink(line) {
      return line.match(this._linkRegex()) || line.match(this._emailRegex())
    },

    _renderTechnicalDetailLine(line, index) {

      var innerHtml = line.replace(this._linkRegex(), '<a href=\'\$1\' target=\'_blank\'>\$1</a>').replace(this._emailRegex(), '<a href=\'mailto:\$1\'>\$1</a>')
      return (
        <div key={'technical_detail_' + index} className='row line font-size-m padding-inset-s' dangerouslySetInnerHTML={{__html: innerHtml}}>
        </div>
      )
    },

    _renderTechnicalDetailLines() {
      return this._technicalDetailLinesWithLinks().map((line, index) => {
        return this._renderTechnicalDetailLine(line, index)
      })
    },

    _renderTechnicalDetail() {

      if(this._hasTechnicalDetail()) {
        return (
          <div key='technical_detail' className='col1of2 padding-right-xs'>
             <div className='field row emboss margin-vertical-xxs margin-right-xs'>
                <div className='row padding-inset-xs'>
                   <div className='col1of2 padding-vertical-xs'>
                      <strong className='font-size-m inline-block'>
                      {_jed('Software Informationen')}
                      </strong>
                   </div>
                   <div className='col1of2'>
                      <textarea autoComplete='off' className='width-full' disabled name='model[technical_detail]' rows='6' type='text' defaultValue={this.props.createItemProps.item.model.technical_detail} />
                   </div>
                </div>
                <div className='list-of-lines even padding-bottom-xxs'>
                  {this._renderTechnicalDetailLines()}
                </div>
             </div>
          </div>

        )

      } else {
        return null
      }
    },

    _renderAttachmentsRows() {

      return this.props.createItemProps.model_attachments.map((a, index) => {
        return (
          <div key={'attachment_' + index} className='row line font-size-xs focus-hover-thin' data-type='inline-entry'>
             <div className='line-col col7of10 text-align-left'>
                <a className='blue' href={a.public_filename} target='_blank'>
                {a.filename}
                </a>
             </div>
             <div className='line-col col3of10 text-align-right'></div>
          </div>
        )
      })

    },

    _renderAttachments() {

      if(this._hasAttachments()) {
        return (

          <div key='attachments' className='col1of2 padding-right-xs'>
             <div id='attachments'>
                <div className='field row emboss margin-vertical-xxs margin-right-xs'>
                   <div className='row padding-inset-xs'>
                      <div className='col1of2 padding-vertical-xs'>
                         <strong className='font-size-m inline-block'>
                         {_jed('Attachments')}
                         </strong>
                      </div>
                      <div className='col1of2'>
                         <div className='row'>
                            <div className='col1of3'></div>
                         </div>
                      </div>
                   </div>
                   <div className='list-of-lines even padding-bottom-xxs'>
                     {this._renderAttachmentsRows()}
                   </div>
                </div>
             </div>
          </div>
        )
      } else {
        return null
      }
    },

    _renderSoftwareDetail() {
      if(this._isLicense() && (this._hasTechnicalDetail() || this._hasAttachments())) {
        return _.compact([
          <div key='separator' className='separated-top margin-bottom-m'></div>
          ,
          <h2 key='title' className='headline-m padding-bottom-m' style={{clear: 'both'}}>Software</h2>
          ,
          <div key='content' className='row margin-bottom-l'>
            {this._renderTechnicalDetail()}
            {this._renderAttachments()}
          </div>

        ])
      } else {
        return null
      }
    },

    _renderAutocomplete() {
      var l = window.lodash

      var makeCall = (term, callback) => {
        // NOTE: only search when there is a search term!
        if (l.isEmpty(term)) return false

        window.leihsAjax.getAjax(
          '/manage/' + this.props.createItemProps.inventory_pool.id + '/items?paginate=true&search_term=' + term + '&not_packaged=true&packages=false&retired=false',
          {},
          (status, response) => {
            var ids = l.join(
              l.map(
                response,
                (r) => '&' + encodeURIComponent('ids[]') + '=' + r.model_id
              ),
              ''
            )

            if (ids.length > 0) {
              window.leihsAjax.getAjax(
                '/manage/' + this.props.createItemProps.inventory_pool.id + '/models?paginate=false' + ids,
                {},
                (status2, response2) => {

                  callback(
                    _.map(
                      response,
                      (r) => {

                        var model = l.find(response2, (m) => m.id == r.model_id)


                        return {
                          id: r.id,
                          label: r.inventory_code,
                          currentLocation: r.current_location,
                          inventoryCode: r.inventory_code,
                          value: {
                            item: l.cloneDeep(r),
                            model: l.cloneDeep(model)
                          }
                        }
                      }
                    )
                  )
                }
              )
            } else {
              callback([])
            }
          }
        )
      }

      var liARenderer = (row) => {
        return (
          <a className='ui-menu-item-wrapper'>
            <div className='row text-ellipsis'>
              <div className='col1of3'>
                <strong>{row.inventoryCode}</strong>
              </div>
              <div className='col2of3 text-ellipsis' title={this._renderModelName(row.value.model)}>
                {this._renderModelName(row.value.model)}
              </div>
            </div>
          </a>
        )
      }


      return (
        <BasicAutocomplete
          ref='create-item-autocomplete'
          inputClassName='has-addon width-full'
          element='div'
          inputId='search-item'
          dropdownWidth='424px'
          label={''}
          _makeCall={makeCall}
          onChange={this.props.onSelectChildItem}
          wrapperStyle={{display: 'inline-block', clear: 'none', marginRight: '10px'}}
          liARenderer={liARenderer}
          resetAfterSelection={true}
        />
      )
    },

    _renderModelName(model) {
      if(model.version) {
        return model.product + ' ' + model.version
      } else {
        return model.product
      }

    },



    _renderSelectedItems() {

      return _.map(
        this.props.packageChildItems,
        (i) => {
          return (
            <div key={i.item.id} className='row emboss padding-bottom-xxs margin-bottom-xxs' data-id='00231cb7-331d-4bf4-94f8-a22c5a1f03b0' data-new='' data-type='inline-entry'>
              <div className='row padding-inset-xxs'>
                <div className='col1of4 padding-left-s padding-top-xs'>
                  <strong className='font-size-m inline-block'>
                    {i.item.inventory_code}
                  </strong>
                </div>
                <div className='col2of4 padding-top-xs'>
                  {this._renderModelName(i.model)}
                </div>
                <div className='col1of4 text-align-right'>
                  <button onClick={(e) => this.props.onRemoveChildItem(i.item.id)} className='button small inset' data-remove='' type='button'>{_jed('Remove')}</button>
                </div>
              </div>
            </div>
          )
        }
      )


    },


    _renderPackageTitle() {

      if(!this.props.createItemProps.for_package) {
        return null
      }

      return (
        <h2 className='headline-m padding-bottom-m'>{_jed('Package')}</h2>
      )

    },


    _renderPackageSelectItem() {

      if(!this.props.createItemProps.for_package) {
        return null
      }

      return (
        <div className='margin-bottom-m'>
          <h2 className='headline-m padding-bottom-m'>{_jed('Content')}</h2>
          <div className='row emboss margin-vertical-xxs margin-right-xs'>
            <div className='row padding-inset-xs'>
              <div className='col1of2 padding-vertical-xs'>
                <strong className='font-size-m inline-block'>{_jed('Add %s', _jed('Item'))}</strong>
              </div>
              <div className='col1of2'>
                <div className='row'>
                  {this._renderAutocomplete()}
                </div>
              </div>
            </div>
          </div>
          <div className='row' id='items'>
            {this._renderSelectedItems()}
          </div>
        </div>
      )

    },

    render () {

      var createItemProps = this.props.createItemProps

      var fieldRenderer = (fieldModel, fieldModels, onChange, showInvalids, onClose, dependencyValue, dataDependency) => {

        var item = createItemProps.item
        var inventoryCodeProps = {
          next_code: createItemProps.next_code,
          lowest_code: createItemProps.lowest_code,
          highest_code: createItemProps.highest_code,
        }

        return (
          CreateItemFieldSwitch.renderField(
            fieldModel,
            dependencyValue,
            dataDependency,
            (value) => onChange(fieldModel.field.id, value),
            item,
            inventoryCodeProps,
            showInvalids,
            onClose,
            true
          )
        )



      }


      var formClass = null
      if(this.props.createItemProps.for_package) {
        formClass = 'padding-top-s'
      }

      return (
        <div className='padding-horizontal-m'>
          {this._renderNotifications()}
          {this._renderPackageSelectItem()}
          <form id='form' className={formClass}>
            {this._renderPackageTitle()}
            <input disabled='disabled' name='copy' type='hidden' />
            {RenderCreateItem._renderColumns(this.props.fields, this.props.fieldModels,
              this.props.onChange, this.props.showInvalids, this.props.onClose, fieldRenderer)}
          </form>
          {this._renderSoftwareDetail()}
        </div>
      )
    }
  })
})()
