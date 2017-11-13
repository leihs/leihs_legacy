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
      var newValue = event.target.value
      if(newValue == '') {
        newValue = null
      }
      this.props.selectedValue.value.selection = event.target.value
      this.props.onChange()
    },



    _renderSelectValues(selectedValue) {
      return selectedValue.field.values.map((value) => {

        var renderValue = value.value
        if(renderValue == null || renderValue == undefined) {
          renderValue = ''
        }

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
          <select className='width-full' onChange={this._onChange} value={selectedValue.value.selection}
            name={'item' + BackwardTestCompatibility._getFormName(selectedValue)}>
            {this._renderSelectValues(selectedValue)}
          </select>
        </div>
      )

    }
  })
})()
