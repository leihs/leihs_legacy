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


  _dmyToString(dmy) {
    if(dmy) {
      var dayString = '' + (dmy.day + 1)
      var monthString = '' + (dmy.month + 1)
      var yearString = '' + dmy.year

      if(dayString.length == 1) {
        dayString = '0' + dayString
      }
      if(monthString.length == 1) {
        monthString = '0' + monthString
      }

      return yearString + '-' + monthString + '-' + dayString

    } else {
      return null
    }

  },

  _parseDate(string) {

    var parts = []

    if(string.indexOf('.') > - 1) {
      parts = string.split('.')
    }
    if(parts.length != 3) {
      return null
    }

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

    try {
      var toParse = yearString + '-' + monthString + '-' + dayString
      var timestamp = Date.parse(toParse)
      if(isNaN(timestamp)) {
        return null
      }

      var date = new Date(timestamp);

      return date


    } catch (error) {
      return null
    }


  },

  _parseDayMonthYear(string) {
    var date = this._parseDate(string);
    if(!date) {
      return null
    }

    return this._getDayMonthYear(date);


  },

  _getDayMonthYear(date) {
    return {
      day: date.getDate() - 1,
      month: date.getMonth(),
      year: date.getFullYear()
    }
  },

  _checkDateStringIsValid(d) {

    if(this._parseDate(d)) {
      return true
    } else {
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
      // case 'attachment':
      //   return <InputAttachment selectedValue={selectedValue} onChange={onChangeSelectedValue} />
      //   break
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

  renderField (selectedValue, dependencyValue, onChange, createItemProps, showInvalids, onClose) {

    var error = showInvalids && this._isFieldInvalid(selectedValue)

    if(selectedValue.field.id == 'inventory_code') {

      return (
        <InputInventoryCode onClose={onClose} selectedValue={selectedValue} onChange={onChange} createItemProps={createItemProps} error={error} />
      )


    } else if(selectedValue.field.type == 'attachment') {

      return (
        <InputAttachment onClose={onClose} selectedValue={selectedValue} onChange={onChange} error={error} />
      )

    } else {

      var fieldClass = 'field row emboss padding-inset-xs margin-vertical-xxs margin-right-xs'
      if(error) {
        fieldClass += ' error'
      }
      if(selectedValue.hidden) {
        fieldClass += ' hidden'
      }

      return (

        <div className={fieldClass} data-editable='true' data-id='inventory_code' data-required='true' data-type='field'>
          <div className='row'>
            {RenderFieldLabel._renderFieldLabel(selectedValue.field, onClose)}
            {this._inputByType(selectedValue, onChange, dependencyValue)}
          </div>
        </div>

      )



    }


  }



}
