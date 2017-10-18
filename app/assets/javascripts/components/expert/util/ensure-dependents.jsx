
window.EnsureDependents = {

  _ensureDependentsRecursive(selectedValue, fields, fieldSpecific) {

    var dependents = fields.filter((field) => {

      if(field.values_dependency_field_id == selectedValue.field.id && fieldSpecific._hasValue(selectedValue)) {
        return true;
      }

      var isDependent = field.visibility_dependency_field_id == selectedValue.field.id
      if(!isDependent) {
        return false;
      }

      var correctDependencyValue = fieldSpecific._isDependencyValue(selectedValue, field.visibility_dependency_value)
      if(!correctDependencyValue) {
        return false;
      }

      return true

    })


    selectedValue.dependents = dependents.map((dependent) => {

      var existings = selectedValue.dependents.filter((existing) => dependent.id == existing.field.id)
      if(existings.length > 0) {
        return existings[0]
      } else {
        return {
          field: dependent,
          value: fieldSpecific._createEmptyValue(dependent),
          col: selectedValue.col,
          dependents: [],
          hidden: (dependent.hidden ? true : false)
        }

      }
    })


    selectedValue.dependents.forEach((dependent) =>
      this._ensureDependentsRecursive(dependent, fields, fieldSpecific)
    )

  },



  _ensureDependents(selectedValues, fields, fieldSpecific) {

    if(!selectedValues) {
      return;
    }
    selectedValues.forEach((selectedValue) => {
      this._ensureDependentsRecursive(selectedValue, fields, fieldSpecific)
    })
  },


}
