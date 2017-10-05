(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputSelect = React.createClass({
    propTypes: {
    },


    _onChange(event) {
      event.preventDefault()
      this.props.selectedValue.value.selection = this.props.selectedValue.field.values[parseInt(event.target.value)].value
      console.log('fire on change')
      this.props.onChange()
    },


    _getFormName(selectedValue) {

      var field = selectedValue.field
      if (field.form_name) {
        return '[' + field.form_name + ']'
      } else if (field.attribute instanceof Array) {
        return _.reduce(
          field.attribute,
          (result, part) => {
            return result + '[' + part + ']'
          },
          ''
        )
        this._setValue(result, field.attribute, value)
      } else {
        return '[' + field.attribute + ']'
      }
    },

    _renderSelectValues(selectedValue) {
      return selectedValue.field.values.map((value, index) => {

        return (
          <option key={'' + index} value={'' + index}>
            {_jed(value.label)}
          </option>
        )
      })

    },

    render () {
      const props = this.props
      const selectedValue = props.selectedValue

      var index = - 1
      for(var i = 0; i < selectedValue.field.values.length; i++) {
        if(selectedValue.field.values[i].value === selectedValue.value.selection) {
          index = i
        }
      }

      return (
        <div className='col1of2'>
          <select className='width-full' onChange={this._onChange} value={'' + index}
            name={'item' + this._getFormName(selectedValue)}>
            {this._renderSelectValues(selectedValue)}
          </select>
        </div>
      )

    }
  })
})()
