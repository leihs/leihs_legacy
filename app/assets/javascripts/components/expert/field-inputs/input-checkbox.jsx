(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputCheckbox = React.createClass({
    propTypes: {
    },

    _onChange(event, value) {
      // var value = this.props.selectedValue.field.values[index].value

      var selections = this.props.selectedValue.value.selections
      if(event.target.checked) {
        selections = _.uniq(selections.concat(value))
      } else {
        selections = _.reject(selections, (s) => s === value)
      }

      this.props.selectedValue.value.selections = selections
      this.props.onChange()
    },

    _renderCheckboxValues(selectedValue) {


      return selectedValue.field.values.map((value) => {

        var checked = _.filter(selectedValue.value.selections, (s) => s === value.value).length > 0

        return (
          <label onClick={(event) => {this._onChange(event, value.value)}} key={value.value} className='padding-inset-xxs'>
            <input onChange={(event) => {this._onChange(event, value.value)}} type='checkbox' checked={checked} value={value.value} />
            {checked}
            <span className='font-size-m'>{' ' + _jed(value.label)}</span>
          </label>
        )
      })


    },


    render () {
      const props = this.props
      const selectedValue = props.selectedValue

      return (



        <div className='col1of2' data-type='value'>
          <div className='padding-inset-xxs'>
            {this._renderCheckboxValues(selectedValue)}
          </div>
        </div>
      )


    }
  })
})()
