(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React

  window.CreateItem = React.createClass({
    propTypes: {
    },

    getInitialState () {
      return {
        loadingFields: 'initial',
        fields: null,
        showInvalids: false
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
      this._fetchFields()
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

    _readyContent() {
      return (
        <CreateItemContent ref={(component) => this.createItemContent = component} fields={this.state.fields}
          createItemProps={this.props} showInvalids={this.state.showInvalids} />
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

    _renderTitle() {
      return (
        <div className='col1of2'>
          <h1 className='headline-l'>Neuen Gegenstand erstellen</h1>
          <h2 className='headline-s light'>Geben Sie alle erforderlichen Informationen an</h2>
        </div>
      )
    },

    _serializeExtensibleFieldValue(fieldModel) {

      var field = fieldModel.field
      var value = fieldModel.value

      if(field.type == 'autocomplete') {
        return value.text
      } else {
        throw 'Not supported field type: ' + field.type
      }
    },

    _serializeFieldValue(fieldModel) {

      var field = fieldModel.field
      var value = fieldModel.value

      switch(field.type) {
        case 'text':
          return value.text
          break
        case 'autocomplete-search':
          return value.id
          break
        case 'autocomplete':
          return value.id
          break
        case 'textarea':
          return value.text
          break
        case 'select':
          return value.selection
          break
        case 'radio':
          return value.selection
          break
        case 'date':
          return value.at
          break
        case 'attachment':
          return ''
          break
        default:
          throw 'Unexpected type: ' + field.type
      }
    },

    _recursiveFieldModels(fieldModel, fieldModels) {

      if(fieldModel.dependents && fieldModel.dependents.length > 0) {

        return _.reduce(
          fieldModel.dependents,
          (result, dependent) => {
            return result.concat(
              this._recursiveFieldModels(dependent, result)
            )
          },
          fieldModels.concat(fieldModel)
        )
      } else {
        return fieldModels.concat(fieldModel)
      }

    },

    _flatFieldModels() {
      return _.reduce(
        this.createItemContent.state.fieldModels,
        (result, fieldModel) => {
          return result.concat(
            this._recursiveFieldModels(fieldModel, [])
          )
        },
        []
      )
    },

    _isFieldModelForSubmit(fieldModel) {
      return fieldModel.field.type != 'attachment' && !fieldModel.field.exclude_from_submit
    },

    _fieldModelsForSubmit() {
      return _.filter(
        this._flatFieldModels(),
        (fieldModel) => this._isFieldModelForSubmit(fieldModel)
      )
    },


    // Should be replaced by lodash.
    _setValue(obj, path, val) {
      var fields = path
      var result = obj
      for (var i = 0, n = fields.length; i < n && result !== undefined; i++) {
        var field = fields[i]
        if (i === n - 1) {
          result[field] = val
        } else {
          if (typeof result[field] === 'undefined' || !_.isObject(result[field])) {
            result[field] = {}
          }
          result = result[field]
        }
      }
    },

    _serializeItem(bypassSerialNumberValidation) {

      var base = {};
      if(bypassSerialNumberValidation) {
        base.skip_serial_number_validation = 'true'
      } else {
        base.skip_serial_number_validation = 'false'
      }

      return _.reduce(
        this._fieldModelsForSubmit(),
        (result, fieldModel) => {

          var field = fieldModel.field

          var value = this._serializeFieldValue(fieldModel)
          if (field.form_name) {
            result[field.form_name] = value
          } else if (field.attribute instanceof Array) {
            this._setValue(result, field.attribute, value)
          } else {
            result[field.attribute] = value
          }

          if(field.extensible) {
            var extensibleValue = this._serializeExtensibleFieldValue(fieldModel)
            this._setValue(result, field.extended_key, extensibleValue)
          }

          return result
        },
        base
      )
    },

    _isValid(fieldModel) {

      var isValid = !CreateItemFieldSwitch._isFieldInvalid(fieldModel)

      return _.reduce(
        fieldModel.dependents,
        (memo, dep) => {
          return memo && this._isValid(dep)
        },
        isValid
      )

    },

    _clientValidation() {

      return _.reduce(
        this.createItemContent.state.fieldModels,
        (memo, fm) => {
          return memo && this._isValid(fm)
        },
        true
      )
    },


    _attachmentsFieldModel() {
      return _.find(this.createItemContent.state.fieldModels, (fm) => fm.field.id == 'attachments')
    },

    _attachementFiles() {
      return this._attachmentsFieldModel().value.fileModels
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
        this._attachementFiles(),
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
      if(redirectUrl) {
        window.location = redirectUrl + '?flash[success]=' + _jed('Item saved')
      } else {
        window.location = this.props.inventory_path
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
        this._attachementFiles(),
        this._submitAttachmentsCallback(itemId, redirectUrl)
      )
    },

    _showSuccessFlash() {

      App.Flash({
        type: "error",
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
        item: this._serializeItem(bypassSerialNumberValidation),
      }

      if(copy) {
        data.copy = true
      }

      $.ajax({
        url: this.props.save_path,
        data: data,
        dataType: 'json',
        method: 'POST'
      }).done((data) => {
        if(this._attachementFiles().length > 0) {
          this._submitAttachments(data.id, data.redirect_url)
        } else {
          this._forward(data.redirect_url)
        }

      }).error((data) => {
        if(data.responseJSON.can_bypass_unique_serial_number_validation) {
          this._showSerialNumberModal(data.responseJSON.message, copy)
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

    _renderTitleButtons() {

      return (
        <div className='col1of2 text-align-right'>
          <button className='button white' data-placement='top' data-toggle='tooltip' id='show-all-fields' style={{display: 'none'}} title='Alle versteckten Felder wieder anzeigen'>Alle Felder anzeigen</button>
          <a className='button grey' href={this.props.inventory_path}>{_jed('Cancel')}</a>
          <div className='multibutton'>
            <button autoComplete='off' className='button green' id='save' onClick={this._onSave}>
              {_jed('Save Item')}
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

    render () {

      return (
        <div className='row content-wrapper min-height-xl min-width-full straight-top'>
          {this._renderTitleAndButtons()}
          {this._content()}
        </div>
      )
    }
  })
})()
