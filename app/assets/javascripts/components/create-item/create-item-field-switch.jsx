window.CreateItemFieldSwitch = {

  _hasValue(selectedValue) {
    switch(selectedValue.field.type) {
      case 'text':
        return selectedValue.value.text.trim().length > 0
        break
      case 'autocomplete-search':
        return selectedValue.value.id != null
        break
      case 'autocomplete':
        return selectedValue.value.id != null
        break
      case 'textarea':
        return selectedValue.value.text.trim().length > 0
        break
      case 'select':
        return selectedValue.value.selection != null
        break
      case 'radio':
        return selectedValue.value.selection != null
        break
      case 'date':
        return selectedValue.value.at.trim().length > 0
        break
      case 'attachment':
        return selectedValue.value.fileModels.length > 0
        break
      default:
        throw 'Unexpected type: ' + selectedValue.field.type
    }
  },

  _checkDateStringIsValid(d) {

    var parts = []

    if(d.indexOf('.') > -1) {
      parts = d.split('.')
    } else if(d.indexOf('/') > -1) {
      parts = d.split('/')
    }
    if(parts.length != 3) {
      return false
    }

    try {
      var dayString = parts[0]
      var monthString = parts[1]
      var yearString = parts[2]

      if(dayString.length < 1 || monthString.length < 1 || yearString.length < 1) {
        return false
      }

      if(dayString.length == 1) {
        dayString = '0' + dayString
      }
      if(monthString.length == 1) {
        monthString = '0' + monthString
      }
      while(yearString.length < 4) {
        yearString = '0' + yearString
      }

      var toParse = yearString + '-' + monthString + '-' + dayString
      if(isNaN(Date.parse(toParse))) {
        return false
      }

      return true


    } catch (error) {
      return false
    }

  },

  _isValid(selectedValue) {

    if(selectedValue.field.type == 'date') {

      var d = selectedValue.value.at
      return this._checkDateStringIsValid(d)

    } else {
      return true
    }

  },

  _createEmptyValue (field) {
    switch(field.type) {
      case 'text':
        return {text: ''}
        break
      case 'autocomplete-search':
        return {
          text: '',
          id: null
        }
        break
      case 'autocomplete':
        return {
          text: '',
          id: null
        }
        break
      case 'textarea':
        return {text: ''}
        break
      case 'attachment':
        return {fileModels: []}
        break
      case 'select':
        return {selection: field.default}
        break
      case 'radio':
        return {selection: field.default}
        break
      case 'date':
        return {at: ''}
        break
      default:
        throw 'Unexpected type: ' + field.type
    }
  },

  _isDependencyValue(selectedValue, fieldDependencyValue) {
    switch(selectedValue.field.type) {
      case 'text':
        return selectedValue.value.text == fieldDependencyValue
        break
      case 'autocomplete-search':
        return selectedValue.value.text == fieldDependencyValue
        break
      case 'autocomplete':
        return selectedValue.value.id == fieldDependencyValue
        break
      case 'textarea':
        return selectedValue.value.text == fieldDependencyValue
        break
      case 'select':
        return '' + selectedValue.value.selection == fieldDependencyValue
        break
      case 'radio':
        return '' + selectedValue.value.selection == fieldDependencyValue
        break
      case 'date':
        throw 'Not implemented yet.'
        break
      default:
        throw 'Unexpected type: ' + field.type
    }
  },

  _inputByType (selectedValue, onChangeSelectedValue, dependencyValue) {
    switch(selectedValue.field.type) {
      case 'text':
        return <InputText selectedValue={selectedValue} onChange={onChangeSelectedValue} />
        break
      case 'autocomplete-search':
        return <InputAutocompleteSearch onChange={onChangeSelectedValue} selectedValue={selectedValue} />
        break
      case 'autocomplete':
        return <InputAutocomplete selectedValue={selectedValue} dependencyValue={dependencyValue} onChange={onChangeSelectedValue} />
        break
      case 'textarea':
        return <InputTextarea selectedValue={selectedValue} onChange={onChangeSelectedValue} />
        break
      case 'select':
        return <InputSelect selectedValue={selectedValue} onChange={onChangeSelectedValue} />
        break
      case 'radio':
        return <InputRadio selectedValue={selectedValue} onChange={onChangeSelectedValue} />
        break
      case 'date':
        return <InputDate selectedValue={selectedValue} onChange={onChangeSelectedValue} />
        break
      case 'attachment':
        return <InputAttachment selectedValue={selectedValue} onChange={onChangeSelectedValue} />
        break
      default:
        throw 'Unexpected type: ' + selectedValue.field.type
    }
  },

  _isFieldInvalid(fieldModel) {
    if(fieldModel.field.required) {
      return (!this._hasValue(fieldModel) || !this._isValid(fieldModel))
    } else {
      return this._hasValue(fieldModel) && !this._isValid(fieldModel)
    }
  },

  renderField (selectedValue, dependencyValue, onChange, createItemProps, showInvalids) {

    var error = showInvalids && this._isFieldInvalid(selectedValue)

    if(selectedValue.field.id == 'inventory_code') {

      return (
        <InputInventoryCode selectedValue={selectedValue} onChange={onChange} createItemProps={createItemProps} error={error} />
      )


    } else if(selectedValue.field.type == 'attachment') {

      return (
        <InputAttachment selectedValue={selectedValue} onChange={onChange} error={error} />
      )

    } else {

      var fieldClass = 'field row emboss padding-inset-xs margin-vertical-xxs margin-right-xs'
      if(error) {
        fieldClass += ' error'
      }

      return (

        <div className={fieldClass} data-editable='true' data-id='inventory_code' data-required='true' data-type='field'>
          <div className='row'>
            {RenderFieldLabel._renderFieldLabel(selectedValue.field)}
            {this._inputByType(selectedValue, onChange, dependencyValue)}
          </div>
        </div>

      )



    }


  }



}
