window.FieldsDropdownData = {


  _onlyMainFields (allFields) {
    return allFields.filter((field) => {
      return !field['visibility_dependency_field_id'] && !field['values_dependency_field_id'] && field.id != 'attachments'
    })

  },

  _notSelectedFields (allFields, selectedValues) {
    return this._onlyMainFields(allFields).filter((field) => {

      return selectedValues.filter((selectedValue) => {
        return selectedValue.field.id == field.id
      }).length == 0


    })
  },

  _filteredFields (allFields, selectedValues, filter) {
    return this._notSelectedFields(allFields, selectedValues).filter((field) => {

      return _jed(field.label).toLowerCase().indexOf(filter.toLowerCase()) >= 0

    })

  },

  _determineFields (allFields, selectedValues, term) {

    if(term.trim() == '') {
      return this._notSelectedFields(allFields, selectedValues)
    } else {
      return this._filteredFields(allFields, selectedValues, term.trim())
    }

  },

  _determineData(allFields, selectedValues, term) {

    return this._determineFields(allFields, selectedValues, term).sort((a, b) => _jed(a.label).localeCompare(_jed(b.label))).map(
      (field) => {
        return {
          id: field.id,
          label: field.label
        }
      }
    )
  }


}
