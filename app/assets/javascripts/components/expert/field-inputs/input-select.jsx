(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputSelect = window.createReactClass({
    propTypes: {
    },


    _onChange(event) {
      event.preventDefault()
      var newValue = this._parseValue(event.target.value)
      this.props.selectedValue.value.selection = event.target.value
      this.props.onChange()
    },


    _serializeValue(value) {
      if(value == null || value == undefined) {
        return ''
      } else {
        return value
      }

    },

    _parseValue(value) {
      if(value == '') {
        return null
      } else {
        return value
      }
    },


    _renderSelectValues(selectedValue) {
      return selectedValue.field.values.map((value) => {

        var renderValue = this._serializeValue(value.value)

        return (
          <option key={value.value} value={renderValue}>
            {_jed(value.label)}
          </option>
        )
      })

    },

    render () {
      const props = this.props
      const selectedValue = props.selectedValue

      return (
        <div className='col1of2'>
          <select className='width-full' onChange={this._onChange} value={this._serializeValue(selectedValue.value.selection)}
            name={'item' + BackwardTestCompatibility._getFormName(selectedValue)}>
            {this._renderSelectValues(selectedValue)}
          </select>
        </div>
      )

    }
  })
})()
