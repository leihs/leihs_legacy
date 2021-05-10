;(() => {
  // NOTE: only for linter and clarity:
  /* global _, _jed, $, setUrlParams */
  /* global App */
  /* global React */
  /* global PropTypes */
  /* global CreateItemFieldSwitch, CreateItemContent */

  const f = window.lodash

  // NOTE: This is the server-side limit (needed because the result page holds uuids in params for all created items, also to protect against mistakes)
  const BATCH_CREATE_MAX_QUANTITY = 100
  // NOTE: those fields are only relevant for a *single* item instance. the list comes from the "copy item" action, which resets those fields on copy.
  // <https://github.com/leihs/leihs/issues/1015#issuecomment-775999512>
  const ITEM_FIELDS_DISABLED_FOR_BATCH = [
    'owner',
    // 'inventory_code', // already handled explicitly in the Field component itself, so we cant remove the field!
    'serial_number',
    'name',
    'last_check',
    'attachments'
  ]

  window.CreateItem = window.createReactClass({
    propTypes: {},

    initialPackageChildItems() {
      if (this.props.edit && this.props.for_package && this.props.children) {
        var l = window.lodash
        return l.map(this.props.children, (c) => {
          return {
            item: c.json,
            model: c.json.model
          }
        })
      } else {
        return []
      }
    },

    // https://reactjs.org/docs/legacy-context.html
    childContextTypes: {
      hackyForPackage: PropTypes.bool,
      isBatchCreate: PropTypes.bool,
      batchCreateInventoryCodePrefix: PropTypes.string
    },
    // NOTE: We need this hack to pass the forPackage value to the mdoel_id input since
    // the current field config does not let us pass this information if we
    // only should list package models or not.
    getChildContext() {
      return {
        hackyForPackage: this.props.for_package,
        isBatchCreate: this._isBatchCreate(),
        batchCreateInventoryCodePrefix: this.props.code_prefix
      }
    },

    getInitialState() {
      return {
        quantity: 1,
        loadingFields: 'initial',
        fields: null,
        showInvalids: false,
        fieldModels: [],
        showError: false,
        errorMessage: '',
        packageChildItems: this.initialPackageChildItems()
      }
    },

    _targetType() {
      return this.props.item_type
    },

    _fetchFields() {
      this.setState({ loadingFields: 'loading' })
      App.Field.ajaxFetch({
        data: $.param({ target_type: this._targetType() })
      }).done((data) => {
        var fields = data
        if (this.props.for_package) {
          fields = _.filter(data, (f) => f.forPackage || f.id == 'model_id')
        }

        this.setState({
          loadingFields: 'done',
          fields: fields,
          fieldModels: this._createFieldModels(fields, this.props.item)
        })
      })
    },

    _createFieldModels(fields, item) {
      if (item) {
        return window.FieldModels._createEditFieldModels(
          fields,
          item,
          this._fieldSwitch,
          this.props.attachments
        )
      } else {
        return window.FieldModels._createNewFieldModels(
          fields,
          this.props.next_code,
          this.props.inventory_pool,
          this._fieldSwitch
        )
      }
    },

    componentDidMount() {
      this._fetchFields()
    },

    _fieldSwitch() {
      return {
        _hasValidValue: CreateItemFieldSwitch._hasValidValue,
        _createEmptyValue: CreateItemFieldSwitch._createEmptyValue,
        _isDependencyValue: CreateItemFieldSwitch._isDependencyValue
      }
    },

    onChange(fieldId, value) {
      var l = window.lodash
      var fieldModels = l.cloneDeep(this.state.fieldModels)
      window.FieldModels.findFieldModel(fieldModels, fieldId).value = value
      window.FieldModels._ensureDependents(fieldModels, this.state.fields, this._fieldSwitch)
      this.setState({ fieldModels: fieldModels })
    },

    _loadingFields() {
      var loading = <div className="loading-bg" />

      return (
        <div className="table">
          <div className="table-row">
            <div
              className="table-cell list-of-lines even separated-top padding-bottom-s min-height-l"
              id="inventory"
              style={{ border: '0px' }}>
              <div className="height-s" />
              {loading}
              <div className="height-s" />
            </div>
          </div>
        </div>
      )
    },

    _onShowAll() {
      var url = '/manage/' + this.props.inventory_pool.id + '/fields'
      $.ajax({
        url: url,
        type: 'post',
        data: {
          _method: 'delete'
        }
      }).done(() => {
        var l = window.lodash
        var fieldModels = l.cloneDeep(this.state.fieldModels)
        _.each(fieldModels, (fm) => {
          fm.hidden = false
        })

        this.setState({ fieldModels: fieldModels })
      })
    },

    _onClose(fieldModel) {
      var url = '/manage/' + this.props.inventory_pool.id + '/fields/' + fieldModel.field.id
      $.ajax({
        url: url,
        type: 'post'
      }).done(() => {
        var l = window.lodash
        var fieldModels = l.cloneDeep(this.state.fieldModels)
        _.each(fieldModels, (fm) => {
          if (fm.field.id == fieldModel.field.id) {
            fm.hidden = true
          }
        })

        this.setState({ fieldModels: fieldModels })
      })
    },

    onSelectChildItem(result) {
      // var term = result.term
      var id = result.id
      var value = result.value
      if (id) {
        this.setState((old) => {
          var l = window.lodash
          return {
            packageChildItems: l.concat(
              [value],
              l.reject(old.packageChildItems, (v) => v.item.id == value.item.id)
            )
          }
        })
      }
    },

    onRemoveChildItem(itemId) {
      this.setState((old) => {
        var l = window.lodash
        return {
          packageChildItems: l.reject(old.packageChildItems, (v) => v.item.id == itemId)
        }
      })
    },

    _readyContent() {
      const isBatch = this._isBatchCreate()
      const isCreating = !this.props.edit
      const isAPackage = !!this.props.for_package
      const isPartOfAPackage = !!this.props.parent
      const isSoftwareLicense = this.props.item_type === 'license'
      const isCreatingNewItem = isCreating && !isAPackage && !isPartOfAPackage && !isSoftwareLicense
      let fields = this.state.fields
      let fieldModels = this.state.fieldModels

      // NOTE: not implemented for licenses, because they are deprecated
      const quantitySelector = isCreatingNewItem && (
        <div className="ui-create-item-quantity-selector">
          <div
            className="field row emboss padding-inset-xs margin-vertical-xxs margin-right-xs"
            data-editable="true"
            data-id="item_quantity"
            data-required="true"
            data-type="field">
            <div className="row">
              <div className="col1of2 padding-vertical-xs" data-type="key">
                <strong className="font-size-m inline-block">
                  {_jed('create_multiple_items_label_quantity')} *
                </strong>
              </div>
              <div className="col1of2" data-type="value">
                <input
                  type="number"
                  name="item[quantity]"
                  value={this.state.quantity}
                  onChange={({ target: { value: num } }) =>
                    this.setState({ quantity: Math.min(num, BATCH_CREATE_MAX_QUANTITY) })
                  }
                  className="width-full"
                  autoComplete="off"
                  min={1}
                  max={BATCH_CREATE_MAX_QUANTITY}
                  step={1}
                />
              </div>
            </div>
          </div>
        </div>
      )

      // NOTE: if creating multiple, hide certain fields
      if (isBatch) {
        fields = f.reject(fields, (field) => f.includes(ITEM_FIELDS_DISABLED_FOR_BATCH, field.id))
        fieldModels = f.reject(fieldModels, (fieldModel) =>
          f.includes(ITEM_FIELDS_DISABLED_FOR_BATCH, f.get(fieldModel, 'field.id'))
        )
      }

      return (
        // eslint-disable-next-line react/jsx-no-undef
        <CreateItemContent
          fields={fields}
          fieldModels={fieldModels}
          onChange={this.onChange}
          createItemProps={this.props}
          showInvalids={this.state.showInvalids}
          onClose={this._onClose}
          onSelectChildItem={this.onSelectChildItem}
          onRemoveChildItem={this.onRemoveChildItem}
          packageChildItems={this.state.packageChildItems}
          quantitySelector={quantitySelector}
        />
      )
    },

    _fieldsReady() {
      return this.state.loadingFields == 'done'
    },

    _content() {
      if (!this._fieldsReady()) {
        return this._loadingFields()
      } else {
        return this._readyContent()
      }
    },

    _subtitleMessage() {
      if (this.props.edit) {
        _jed('Make changes and save')
      } else {
        _jed('Insert all required information')
      }
    },

    _titleMessage() {
      if (this.props.edit) {
        if (this.props.for_package) {
          return _jed('Edit %s', _jed('Package'))
        } else if (this._targetType() == 'license') {
          return _jed('Edit License')
        } else {
          return _jed('Edit Item')
        }
      } else {
        if (this.props.for_package) {
          return _jed('Create %s', _jed('Package'))
        } else if (this._targetType() == 'license') {
          return _jed('Create new software license')
        } else {
          return _jed('Create new item')
        }
      }
    },

    _renderTitle() {
      return (
        <div className="col1of2">
          <h1 className="headline-l">{this._titleMessage()}</h1>
          <h2 className="headline-s light">{this._subtitleMessage()}</h2>
        </div>
      )
    },

    _flatFieldModels() {
      return window.FieldModels._flatFieldModels(this.state.fieldModels)
    },

    _isFieldModelForSubmit(fieldModel) {
      return (
        fieldModel.field.type != 'attachment' &&
        !fieldModel.field.exclude_from_submit &&
        CreateItemFieldSwitch._isFieldEditable(fieldModel.field, this.props.item)
      )
    },

    _fieldModelsForSubmit() {
      return _.filter(this._flatFieldModels(), (fieldModel) =>
        this._isFieldModelForSubmit(fieldModel)
      )
    },

    _clientValidation() {
      return window.CreateItemValidation._clientValidation(this.state.fieldModels)
    },

    _attachmentsFieldModel() {
      return _.find(this.state.fieldModels, (fm) => fm.field.id == 'attachments')
    },

    _attachmentsFileModels() {
      if (this._attachmentsFieldModel()) {
        return this._attachmentsFieldModel().value.fileModels
      } else {
        return []
      }
    },

    _newAttachementFiles() {
      return _.filter(this._attachmentsFileModels(), (fm) => {
        return fm.type == 'new'
      })
    },

    _uploadFile(itemId, fileModel, callback) {
      var file = fileModel.file

      var formData = new FormData()
      formData.append('data', file)
      formData.append('item_id', itemId)

      $.ajax({
        url: this.props.store_attachment_path,
        data: formData,
        contentType: false,
        method: 'POST',
        processData: false
      })
        .done(() => {
          callback({ result: 'success', fileModel: fileModel })
        })
        .error(() => {
          callback({ result: 'failure', fileModel: fileModel })
        })
    },

    _uploadFileCallback(itemId, fileModels, callback) {
      return (answer) => {
        if (answer.result != 'success') {
          answer.fileModel.result = 'failure'
        } else {
          answer.fileModel.result = 'success'
        }

        this._uploadFiles(itemId, _.rest(fileModels), callback)
      }
    },

    _uploadFiles(itemId, fileModels, callback) {
      if (fileModels.length == 0) {
        callback()
        return
      }

      this._uploadFile(
        itemId,
        _.first(fileModels),
        this._uploadFileCallback(itemId, fileModels, callback)
      )
    },

    _allUploadsSuccessful() {
      return _.reduce(
        this._newAttachementFiles(),
        (result, fileModel) => {
          return result && fileModel.result == 'success'
        },
        true
      )
    },

    _showAttachmentsHintIfNeeded() {
      var message = _jed('%s was saved, but there were problems uploading files', _jed('Item'))
      alert(message)
    },

    _editItemPath(itemId) {
      return '/manage/' + this.props.inventory_pool.id + '/items/' + itemId + '/edit'
    },

    _forward(redirectUrl, withMessage = true) {
      var message = _.string.capitalize(this.props.item_type) + ' saved.'
      var flash = withMessage ? { 'flash[success]': _jed(message) } : {}
      if (redirectUrl) {
        window.location = setUrlParams(redirectUrl, flash)
      } else {
        window.location = setUrlParams(this.props.inventory_path, flash)
      }
    },

    _submitAttachmentsCallback(itemId, redirectUrl) {
      return () => {
        if (!this._allUploadsSuccessful()) {
          this._showAttachmentsHintIfNeeded()
          window.location = this._editItemPath(itemId)
        } else {
          this._forward(redirectUrl)
        }
      }
    },

    _submitAttachments(itemId, redirectUrl) {
      this._showAttachmentLoadingFlash()

      this._uploadFiles(
        itemId,
        this._newAttachementFiles(),
        this._submitAttachmentsCallback(itemId, redirectUrl)
      )
    },

    _showSuccessFlash() {
      App.Flash({
        type: 'error',
        message: _jed('Please provide all required fields')
      })
    },

    _showAttachmentLoadingFlash() {
      var modal = new App.Modal($('<div></div>'))
      modal.undestroyable()
      App.Flash(
        {
          type: 'notice',
          message: _jed('Uploading files - please wait'),
          loading: true
        },
        9999
      )
    },

    _save(bypassSerialNumberValidation, copy) {
      if (!this._clientValidation()) {
        this._showSuccessFlash()
        this.setState({ showInvalids: true })
        return
      } else {
        App.Flash.reset()
      }

      const isBatch = this._isBatchCreate()

      var data = {
        inventory_pool_id: this.props.inventory_pool.id,
        item: window.SerializeItem._serializeItem(
          bypassSerialNumberValidation,
          this._fieldModelsForSubmit()
        )
      }

      if (isBatch) {
        this.setState({ isSaving: true })
        data.quantity = this.state.quantity
      }

      if (this.props.for_package) {
        data.child_items = _.map(this.state.packageChildItems, (i) => {
          return i.item.id
        })
      }

      data.item.attachments_attributes = {}
      _.each(this._attachmentsFileModels(), (fm) => {
        if (fm.delete) {
          data.item.attachments_attributes[fm.id] = {
            id: fm.id,
            _destroy: '1'
          }
        }
      })

      if (copy) {
        data.copy = true
      }

      const showMessage = !isBatch

      $.ajax({
        url: isBatch ? this.props.save_multiple_path : this.props.save_path,
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json',
        method: this.props.edit ? 'PUT' : 'POST'
      })
        .done((data) => {
          if (this._newAttachementFiles().length > 0) {
            this._submitAttachments(data.id, data.redirect_url)
          } else {
            this._forward(data.redirect_url, showMessage)
          }
        })
        .error((res) => {
          const data = res && res.responseJSON
          if (data && data.can_bypass_unique_serial_number_validation) {
            this._showSerialNumberModal(res.responseJSON.message, copy)
          } else if (data) {
            this._showErrorMessage(res.responseJSON.message)
          } else {
            this._showErrorMessage(
              'Unexpected Error!\n' + res.statusText + '\n\n' + res.responseText
            )
          }
        })
    },

    _onSave(event) {
      event.preventDefault()
      this._save(false, false)
    },

    _onSavePackage(event) {
      event.preventDefault()

      this._save(true, false)
    },

    _onSaveAndCopy(event) {
      event.preventDefault()

      this._save(false, true)
    },

    _showSerialNumberModal(message, copy) {
      var saveAnyway = confirm(message + ' ' + _jed('Save anyway') + '?')
      if (saveAnyway) {
        this._save(true, copy)
      } else {
        // Do nothing
      }
    },

    _hasHiddenFields() {
      return _.reduce(
        this._flatFieldModels(),
        (result, fm) => {
          return result || fm.hidden
        },
        false
      )
    },

    _saveButtonText() {
      if (this.props.for_package) {
        return _jed('Save %s', _jed('Package'))
      } else if (this._targetType() == 'license') {
        return _jed('Save %s', _jed('License'))
      } else {
        return _jed('Save %s', _jed('Item'))
      }
    },

    _isBatchCreate() {
      return this.state.quantity > 1
    },

    _isEditing() {
      return !!this.props.edit
    },

    _renderTitleButtons() {
      var displayAllStyle = {}
      if (!this._hasHiddenFields()) {
        displayAllStyle.display = 'none'
      }

      if (this.props.for_package) {
        return (
          <div className="col1of2 text-align-right">
            <button
              onClick={this._onShowAll}
              className="button white"
              data-placement="top"
              data-toggle="tooltip"
              id="show-all-fields"
              style={displayAllStyle}
              title="Alle versteckten Felder wieder anzeigen">
              Alle Felder anzeigen
            </button>
            <a
              className="button grey"
              href={this.props.return_url ? this.props.return_url : this.props.inventory_path}>
              {_jed('Cancel')}
            </a>
            <button
              autoComplete="off"
              className="button green"
              id="save"
              onClick={this._onSavePackage}>
              {this._saveButtonText()}
            </button>
          </div>
        )
      }

      const isSaving = !!this.state.isSaving
      const mainButton = this._isBatchCreate() ? (
        <button className="button green" id="save" onClick={this._onSave} disabled={isSaving}>
          {' '}{this.state.quantity}
          {' × '}
          {this._saveButtonText()} {isSaving && <i className="fa fa-spinner fa-spin"></i>}
        </button>
      ) : (
        <div className="multibutton">
          <button autoComplete="off" className="button green" id="save" onClick={this._onSave}>
            {this._saveButtonText()}
          </button>
          <div className="dropdown-holder inline-block">
            <div className="button green dropdown-toggle">
              <div className="arrow down" />
            </div>
            <ul className="dropdown right" style={{ display: 'none' }}>
              <li>
                <a className="dropdown-item" id="item-save-and-copy" onClick={this._onSaveAndCopy}>
                  <i className="fa fa-copy" />
                  {' ' + _jed('Save and copy')}
                </a>
              </li>
            </ul>
          </div>
        </div>
      )

      return (
        <div className="col1of2 text-align-right">
          <button
            onClick={this._onShowAll}
            className="button white"
            data-placement="top"
            data-toggle="tooltip"
            id="show-all-fields"
            style={displayAllStyle}
            title="Alle versteckten Felder wieder anzeigen">
            Alle Felder anzeigen
          </button>
          <a
            className="button grey"
            href={this.props.return_url ? this.props.return_url : this.props.inventory_path}>
            {_jed('Cancel')}
          </a>
          {mainButton}
        </div>
      )
    },

    _renderTitleButtonsIfReady() {
      if (this._fieldsReady()) {
        return this._renderTitleButtons()
      } else {
        return null
      }
    },

    _renderTitleAndButtons() {
      return (
        <div className="margin-top-l padding-horizontal-m">
          <div className="row">
            {this._renderTitle()}
            {this._renderTitleButtonsIfReady()}
          </div>
        </div>
      )
    },

    _showErrorMessage(message) {
      this.setState({
        showError: true,
        errorMessage: message
      })
    },

    _renderErrorMessage() {
      if (this.state.showError) {
        var onClick = (event) => {
          event.preventDefault()
          this.setState({ showError: false, errorMessage: '' })
        }

        return (
          <div
            id="error-modal"
            style={{
              position: 'absolute',
              top: '0px',
              bottom: '0px',
              left: '0px',
              right: '0px',
              zIndex: '100000'
            }}>
            <div
              style={{
                opacity: '0.8',
                position: 'fixed',
                top: '0',
                right: '0',
                bottom: '0',
                left: '0',
                zIndex: '2000',
                backgroundColor: '#000000'
              }}
            />
            <div
              style={{
                position: 'fixed',
                zIndex: '1000000',
                overflow: 'scroll',
                top: '0px',
                left: '0px',
                bottom: '0px',
                right: '0px'
              }}>
              <div
                style={{
                  position: 'static',
                  marginTop: '100px',
                  marginBottom: '100px',
                  overflow: 'visible'
                }}>
                <div
                  style={{
                    position: 'static',
                    zIndex: '1000000',
                    margin: 'auto',
                    top: '10%',
                    left: '50%',
                    width: '560px',
                    backgroundColor: '#ffffff',
                    borderRadius: '6px',
                    boxShadow: '0 3px 7px rgba(0, 0, 0, 0.3)',
                    backgroundClip: 'padding-box',
                    outline: 'none'
                  }}>
                  <div style={{ fontSize: '1.2em', padding: '20px' }}>
                    {this.state.errorMessage}
                    <div className="row text-align-right">
                      <button type="button" className="button small white" onClick={onClick}>
                        Close
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )
      } else {
        return null
      }
    },

    render() {
      return (
        <div className="row content-wrapper min-height-xl min-width-full straight-top">
          {this._renderErrorMessage()}
          {this._renderTitleAndButtons()}
          {this._content()}
        </div>
      )
    }
  })

  window.CreateItem.displayName = 'CreateItem'
})()
