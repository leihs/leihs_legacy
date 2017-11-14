(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputRadio = React.createClass({
    propTypes: {
    },

    _onChange(event, value) {
      console.log('radio on change')
      this.props.selectedValue.value.selection = value
      this.props.onChange()
    },

    _renderRadioValues(selectedValue) {


      return selectedValue.field.values.map((value) => {

        var checked = value.value === selectedValue.value.selection
        return (
          <label onClick={(event) => {this._onChange(event, value.value)}} key={value.value} className='padding-inset-xxs' htmlFor={selectedValue.field.id + '_' + value.value}>
            <input id={selectedValue.field.id + '_' + value.value} onChange={(event) => {this._onChange(event, value.value)}} checked={checked} type='radio' value={value.value} />
            <span className='font-size-m'>{' ' + _jed(value.label)}</span>
          </label>
        )
      })


    },


    render () {
      const props = this.props
      const selectedValue = props.selectedValue

      return (



        <div className='col1of2'>
          <div className='padding-inset-xxs'>
            {this._renderRadioValues(selectedValue)}
          </div>
        </div>
      )


    }
  })
})()
