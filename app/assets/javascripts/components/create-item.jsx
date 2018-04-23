(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React

  window.CreateItem = window.createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        loadingFields: 'initial',
        fields: null,
        showInvalids: false,
        fieldModels: [],
        showError: false,
        errorMessage: ''
      }
    },


    _targetType() {
        return this.props.item_type
    },


    _fetchFields () {
      this.setState({loadingFields: 'loading'})
      App.Field.ajaxFetch({
        data: $.param({target_type: this._targetType()})
      }).done((data) => {
        this.setState({
          loadingFields: 'done',
          fields: data,
          fieldModels: this._createFieldModels(data, this.props.item)
        })
      })
    },



    _createFieldModels(fields, item) {
      if(item) {
        return window.FieldModels._createEditFieldModels(fields, item, this._fieldSwitch, this.props.attachments)
      } else {
        return window.FieldModels._createNewFieldModels(fields, this.props.next_code, this.props.inventory_pool, this._fieldSwitch)
      }
    },



    componentDidMount () {
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
      this.setState({fieldModels: fieldModels})
    },



    _loadingFields() {
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

    _onShowAll() {

      var url = '/manage/' + this.props.inventory_pool.id + '/fields'
      $.ajax({
        url: url,
        type: 'post',
        data: {
          _method: 'delete'
        }
      }).done((data) => {

        var l = window.lodash
        var fieldModels = l.cloneDeep(this.state.fieldModels)
        _.each(
          fieldModels,
          (fm) => {
            fm.hidden = false
          }
        )

        this.setState({fieldModels: fieldModels})
      })

    },

    _onClose(fieldModel) {
      var url = '/manage/' + this.props.inventory_pool.id + '/fields/' + fieldModel.field.id
      $.ajax({
        url: url,
        type: 'post',
      }).done((data) => {

        var l = window.lodash
        var fieldModels = l.cloneDeep(this.state.fieldModels)
        _.each(
          fieldModels,
          (fm) => {
            if(fm.field.id == fieldModel.field.id) {
              fm.hidden = true
            }
          }
        )

        this.setState({fieldModels: fieldModels})
      })
    },


    _readyContent() {
      return (
        <CreateItemContent fields={this.state.fields}
          fieldModels={this.state.fieldModels}
          onChange={this.onChange}
          createItemProps={this.props} showInvalids={this.state.showInvalids} onClose={this._onClose} />
      )
    },

    _fieldsReady() {
      return this.state.loadingFields == 'done'
    },

    _content () {
      if(!this._fieldsReady()) {
        return this._loadingFields()
      } else {
        return this._readyContent()
      }
    },


    _subtitleMessage() {
      if(this.props.edit) {
        _jed('Make changes and save')
      } else {
        _jed('Insert all required information')
      }
    },

    _titleMessage() {
      if(this.props.edit) {
        if(this._targetType() == 'license') {
          return _jed('Edit License')
        } else {
          return _jed('Edit Item')
        }
      } else {
        if(this._targetType() == 'license') {
          return _jed('Create new software license')
        } else {
          return _jed('Create new item')
        }
      }
    },

    _renderTitle() {

      return (
        <div className='col1of2'>
          <h1 className='headline-l'>{this._titleMessage()}</h1>
          <h2 className='headline-s light'>{this._subtitleMessage()}</h2>
        </div>
      )
    },




    _flatFieldModels() {
      return window.FieldModels._flatFieldModels(this.state.fieldModels)
    },

    _isFieldModelForSubmit(fieldModel) {
      return fieldModel.field.type != 'attachment' && !fieldModel.field.exclude_from_submit && CreateItemFieldSwitch._isFieldEditable(fieldModel.field, this.props.item)
    },

    _fieldModelsForSubmit() {
      return _.filter(
        this._flatFieldModels(),
        (fieldModel) => this._isFieldModelForSubmit(fieldModel)
      )
    },





    _clientValidation() {

      return window.CreateItemValidation._clientValidation(this.state.fieldModels)
    },


    _attachmentsFieldModel() {
      return _.find(this.state.fieldModels, (fm) => fm.field.id == 'attachments')
    },

    _attachmentsFileModels() {
      if(this._attachmentsFieldModel()) {
        return this._attachmentsFieldModel().value.fileModels
      } else {
        return []
      }

    },

    _newAttachementFiles() {
      return _.filter(
        this._attachmentsFileModels(),
        (fm) => {
          return fm.type == 'new'
        }
      )
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
      }).done((data) => {
        callback({result: 'success', fileModel: fileModel})
      }).error((data) => {
        callback({result: 'failure', fileModel: fileModel})
      })
    },

    _uploadFileCallback(itemId, fileModels, callback) {
      return (answer) => {

        if(answer.result != 'success') {
          answer.fileModel.result = 'failure'
        } else {
          answer.fileModel.result = 'success'
        }

        this._uploadFiles(itemId, _.rest(fileModels), callback)
      }
    },

    _uploadFiles(itemId, fileModels, callback) {

      if(fileModels.length == 0) {
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

      var message = _jed(
        '%s was saved, but there were problems uploading files',
        _jed('Item')
      )
      alert(message)
    },


    _editItemPath(itemId)  {
      return '/manage/' + this.props.inventory_pool.id + '/items/' + itemId + '/edit'
    },

    _forward(redirectUrl) {
      var message = _.string.capitalize(this.props.item_type) + ' saved.'
      var flash = '?flash[success]=' + _jed(message)
      if(redirectUrl) {
        window.location = redirectUrl + flash
      } else {
        window.location = this.props.inventory_path + flash
      }
    },

    _submitAttachmentsCallback(itemId, redirectUrl) {
      return () => {
        if(!this._allUploadsSuccessful()) {
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
      App.Flash({
        type: 'notice',
        message: _jed('Uploading files - please wait'),
        loading: true
      }, 9999)

    },

    _save(bypassSerialNumberValidation, copy) {

      if(!this._clientValidation()) {
        this._showSuccessFlash()
        this.setState({showInvalids: true})
        return
      } else {
        App.Flash.reset()
      }

      var data = {
        inventory_pool_id: this.props.inventory_pool.id,
        item: window.SerializeItem._serializeItem(
          bypassSerialNumberValidation,
          this._fieldModelsForSubmit()
        )
      }

      data.item.attachments_attributes = {}
      _.each(
        this._attachmentsFileModels(),
        (fm) => {
          if(fm.delete) {
            data.item.attachments_attributes[fm.id] = {
              id: fm.id,
              _destroy: '1'
            }
          }
        }
      )

      if(copy) {
        data.copy = true
      }
      $.ajax({
        url: this.props.save_path,
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json',
        method: (this.props.edit ? 'PUT' : 'POST')
      }).done((data) => {
        if(this._newAttachementFiles().length > 0) {
          this._submitAttachments(data.id, data.redirect_url)
        } else {
          this._forward(data.redirect_url)
        }

      }).error((data) => {
        if(data.responseJSON.can_bypass_unique_serial_number_validation) {
          this._showSerialNumberModal(data.responseJSON.message, copy)
        }
        else {
          this._showErrorMessage(data.responseJSON.message)
        }
      })
    },

    _onSave(event) {
      event.preventDefault()

      this._save(false, false)
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
      if(this._targetType() == 'license') {
        return _jed('Save %s', _jed('License'))
      } else {
        return _jed('Save %s', _jed('Item'))
      }
    },


    _renderTitleButtons() {

      var displayAllStyle = {}
      if(!this._hasHiddenFields()) {
        displayAllStyle.display = 'none'
      }

      return (
        <div className='col1of2 text-align-right'>
          <button onClick={this._onShowAll} className='button white' data-placement='top' data-toggle='tooltip' id='show-all-fields' style={displayAllStyle} title='Alle versteckten Felder wieder anzeigen'>Alle Felder anzeigen</button>
          <a className='button grey' href={(this.props.return_url ? this.props.return_url : this.props.inventory_path)}>{_jed('Cancel')}</a>
          <div className='multibutton'>
            <button autoComplete='off' className='button green' id='save' onClick={this._onSave}>
              {this._saveButtonText()}
            </button>
            <div className='dropdown-holder inline-block'>
              <div className='button green dropdown-toggle'>
                <div className='arrow down'></div>
              </div>
              <ul className='dropdown right' style={{display: 'none'}}>
                <li>
                  <a className='dropdown-item' id='item-save-and-copy' onClick={this._onSaveAndCopy}>
                    <i className='fa fa-copy'></i>
                    {' ' + _jed('Save and copy')}
                  </a>
                </li>
              </ul>
            </div>
          </div>
        </div>
      )
    },

    _renderTitleButtonsIfReady() {
      if(this._fieldsReady()) {
        return this._renderTitleButtons()
      } else {
        return null
      }
    },

    _renderTitleAndButtons() {

      return (
        <div className='margin-top-l padding-horizontal-m'>
          <div className='row'>
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

      if(this.state.showError) {

        var onClick = (event) => {
          event.preventDefault()
          this.setState({showError: false, errorMessage: ''})
        }

        return (
          <div id='error-modal' style={{position: 'absolute', top: '0px', bottom: '0px', left: '0px', right: '0px', zIndex: '100000'}}>
             <div style={{opacity: '0.8', position: 'fixed', top: '0', right: '0', bottom: '0', left: '0', zIndex: '2000', backgroundColor: '#000000'}}></div>
             <div style={{position: 'fixed', zIndex: '1000000', overflow: 'scroll', top: '0px', left: '0px', bottom: '0px', right: '0px'}}>
                <div style={{position: 'static', marginTop: '100px', marginBottom: '100px', overflow: 'visible'}}>
                   <div style={{position: 'static', zIndex: '1000000', margin: 'auto', top: '10%', left: '50%', width: '560px', backgroundColor: '#ffffff', borderRadius: '6px', boxShadow: '0 3px 7px rgba(0, 0, 0, 0.3)', backgroundClip: 'padding-box', outline: 'none'}}>
                     <div style={{fontSize: '1.2em', padding: '20px'}}>
                       {this.state.errorMessage}
                       <div className='row text-align-right' id='switch'>
                         <button type='button' className='button small white' onClick={onClick}>Close</button>
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

    render () {

      return (
        <div className='row content-wrapper min-height-xl min-width-full straight-top'>
          {this._renderErrorMessage()}
          {this._renderTitleAndButtons()}
          {this._content()}
        </div>
      )
    }
  })
})()
