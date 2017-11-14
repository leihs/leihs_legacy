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
        showInvalids: false,
        fieldModels: []
      }
    },

    _fetchFields () {
      this.setState({loadingFields: 'loading'})
      App.Field.ajaxFetch({
        data: $.param({target_type: 'item'})
      }).done((data) => {
        this.setState({
          loadingFields: 'done',
          fields: data,
          fieldModels: this._createFieldModels(data)
        })
      })
    },




    _onlyMainFields(fields) {

      return fields.filter((f) => {
        return !f['visibility_dependency_field_id'] && !f['values_dependency_field_id']
      })
    },

    _createFieldModels(fields) {

      var fms = this._onlyMainFields(fields).map((field) => {
          return {
              field: field,
              value: this._createEmptyValue(field),
              dependents: [],
              hidden: (field.hidden ? true : false)
            }
        })

      this._ensureDependents(fms, fields)

      return fms
    },

    _getTodayAsString() {
      var today = new Date();
      var dd = today.getDate();
      var mm = today.getMonth() + 1;
      var yyyy = today.getFullYear();

      if(dd < 10) {
          dd = '0' + dd
      }
      if(mm < 10) {
          mm = '0' + mm
      }
      today = dd + '.' + mm + '.' + yyyy;

      return today
    },

    _createEmptyValue(field) {
      if(field.id == 'inventory_code') {
        return {text: this.props.next_code}
      } else if(field.id == 'owner_id') {
        return {
          text: this.props.inventory_pool.name,
          id: this.props.inventory_pool.id
        }
      } else if(field.id == 'last_check') {

        return {
          at: this._getTodayAsString()
        }
      } else {
        return CreateItemFieldSwitch._createEmptyValue(field)
      }
    },

    _ensureDependents(fieldModels, fields) {
      EnsureDependents._ensureDependents(fieldModels, fields, {
        _hasValue: CreateItemFieldSwitch._hasValue,
        _createEmptyValue: CreateItemFieldSwitch._createEmptyValue,
        _isDependencyValue: CreateItemFieldSwitch._isDependencyValue
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

    _onShowAll() {

      var url = '/manage/' + this.props.inventory_pool.id + '/fields'
      $.ajax({
        url: url,
        type: 'post',
        data: {
          _method: 'delete'
        }
      }).done((data) => {

        _.each(
          this.state.fieldModels,
          (fm) => {
            fm.hidden = false
          }
        )

        this.setState({fieldModels: this.state.fieldModels})
      })

    },

    _onClose(fieldModel) {
      var url = '/manage/' + this.props.inventory_pool.id + '/fields/' + fieldModel.field.id
      $.ajax({
        url: url,
        type: 'post',
      }).done((data) => {

        _.each(
          this.state.fieldModels,
          (fm) => {
            if(fm.field.id == fieldModel.field.id) {
              fieldModel.hidden = true
            }
          }
        )

        this.setState({fieldModels: this.state.fieldModels})
      })
    },

    onChange() {
      this._ensureDependents(this.state.fieldModels, this.state.fields)
      this.setState({fieldModels: this.state.fieldModels})
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

    _renderTitle() {
      return (
        <div className='col1of2'>
          <h1 className='headline-l'>{_jed('Create new item')}</h1>
          <h2 className='headline-s light'>{_jed('Insert all required information')}</h2>
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
          var dmy = CreateItemFieldSwitch._parseDayMonthYear(value.at)
          return CreateItemFieldSwitch._dmyToString(dmy)
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
        this.state.fieldModels,
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
        this.state.fieldModels,
        (memo, fm) => {
          return memo && this._isValid(fm)
        },
        true
      )
    },


    _attachmentsFieldModel() {
      return _.find(this.state.fieldModels, (fm) => fm.field.id == 'attachments')
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
      var flash = '?flash[success]=' + _jed('Item saved')
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

    _hasHiddenFields() {

      return _.reduce(
        this._flatFieldModels(),
        (result, fm) => {
          return result || fm.hidden
        },
        false
      )
    },

    _renderTitleButtons() {

      var displayAllStyle = {}
      if(!this._hasHiddenFields()) {
        displayAllStyle.display = 'none'
      }

      return (
        <div className='col1of2 text-align-right'>
          <button onClick={this._onShowAll} className='button white' data-placement='top' data-toggle='tooltip' id='show-all-fields' style={displayAllStyle} title='Alle versteckten Felder wieder anzeigen'>Alle Felder anzeigen</button>
          <a className='button grey' href={this.props.inventory_path}>{_jed('Cancel')}</a>
          <div className='multibutton'>
            <button autoComplete='off' className='button green' id='save' onClick={this._onSave}>
              {_jed('Save %s', _jed('Item'))}
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
