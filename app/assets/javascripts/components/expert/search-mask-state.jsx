(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.SearchMaskState = window.createReactClass({
    propTypes: {
    },


    findSelectedValueRec(selectedValue, fieldId) {
      if(selectedValue.field.id == fieldId) {
        return selectedValue
      } else {
        return this.findSelectedValue(selectedValue.dependents, fieldId)
      }
    },

    findSelectedValue(selectedValues, fieldId) {
      for(var i = 0; i < selectedValues.length; i++) {
        var d = selectedValues[i]
        var fm = this.findSelectedValueRec(d, fieldId)
        if(fm) {
          return fm
        }
      }
      return null
    },

    _onChangeSelectedValue(fieldId, value) {
      var l = window.lodash
      var selectedValues = l.cloneDeep(this.props.selectedValues)
      this.findSelectedValue(selectedValues, fieldId).value = value
      this._fireSelectedValuesChanged(selectedValues)
    },

    _preventSubmit(event) {
      event.preventDefault()
    },


    _onDeselect (event, field) {

      event.preventDefault()

      var l = window.lodash
      var selectedValues = l.cloneDeep(this.props.selectedValues)
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
      var l = window.lodash
      var selectedValues = l.cloneDeep(this.props.selectedValues);
      selectedValues.push({
        field: field,
        value: this.props.fieldSwitch._createEmptyValue(field),
        col: this._determineLeftOrRight(),
        dependents: []
      })

      this._fireSelectedValuesChanged(selectedValues)
    },


    _fireSelectedValuesChanged(selectedValues) {

      EnsureDependents._ensureDependents(selectedValues, this.props.fields, {
        _hasValidValue: this.props.fieldSwitch._hasValue,
        _createEmptyValue: this.props.fieldSwitch._createEmptyValue,
        _isDependencyValue: this.props.fieldSwitch._isDependencyValue
      })
      this.props.selectedValuesChanged(selectedValues)

    },


    render () {

      return (
        <SearchMask onSelect={this._onSelect} fields={this.props.fields}
          selectedValues={this.props.selectedValues} preventSubmit={this._preventSubmit}
          _onDeselect={this._onDeselect}
          _onChangeSelectedValue={this._onChangeSelectedValue}
          fieldSwitch={this.props.fieldSwitch}
          divId={this.props.divId}
        />
      )

    }
  })
})()
