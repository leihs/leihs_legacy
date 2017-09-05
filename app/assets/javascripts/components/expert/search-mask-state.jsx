(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.SearchMaskState = React.createClass({
    propTypes: {
    },


    _onChangeSelectedValue() {
      console.log('on change selected value')
      this._fireSelectedValuesChanged(this.props.selectedValues)
    },

    _preventSubmit(event) {
      event.preventDefault()
    },


    _onDeselect (event, field) {

      event.preventDefault()

      var selectedValues = this.props.selectedValues
      selectedValues = selectedValues.filter((selectedValue) => {
        return selectedValue.field.id != field.id
      })

      this._fireSelectedValuesChanged(selectedValues)

    },


    _determineLeftOrRight () {

      leftCount = this.props.selectedValues.filter((selectedValue) => selectedValue.col == 'left').length
      rightCount = this.props.selectedValues.filter((selectedValue) => selectedValue.col == 'right').length

      if(leftCount <= rightCount) {
        return 'left'
      } else {
        return 'right'
      }

    },




    _onSelect (field) {
      var selectedValues = this.props.selectedValues;
      selectedValues.push({
        field: field,
        value: FieldSwitch._createEmptyValue(field),
        col: this._determineLeftOrRight(),
        dependents: []
      })

      this._fireSelectedValuesChanged(selectedValues)
    },


    _ensureDependentsRecursive(selectedValue) {





      var fields = this.props.fields
      var dependents = fields.filter((field) => {

        if(field.values_dependency_field_id == selectedValue.field.id && FieldSwitch._hasValue(selectedValue)) {
          return true;
        }

        var isDependent = field.visibility_dependency_field_id == selectedValue.field.id
        if(!isDependent) {
          return false;
        }

        var correctDependencyValue = FieldSwitch._isDependencyValue(selectedValue, field.visibility_dependency_value)
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
            value: FieldSwitch._createEmptyValue(dependent),
            col: selectedValue.col,
            dependents: []
          }

        }
      })


      selectedValue.dependents.forEach((dependent) =>
        this._ensureDependentsRecursive(dependent)
      )

    },



    _ensureDependents(selectedValues) {

      console.log('ensure dependents = ' + JSON.stringify(selectedValues))

      if(!selectedValues) {
        return;
      }
      selectedValues.forEach((selectedValue) => {
        this._ensureDependentsRecursive(selectedValue)
      })
    },


    _fireSelectedValuesChanged(selectedValues) {

      this._ensureDependents(selectedValues)
      this.props.selectedValuesChanged(selectedValues)

    },


    render () {


      return (
        <SearchMask onSelect={this._onSelect} fields={this.props.fields}
          selectedValues={this.props.selectedValues} preventSubmit={this._preventSubmit}
          _onDeselect={this._onDeselect}
          _onChangeSelectedValue={this._onChangeSelectedValue}
        />
      )

    }
  })
})()
