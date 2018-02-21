(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputCheckbox = window.createReactClass({
    propTypes: {
    },

    _onChange(event, sel) {
      // var value = this.props.selectedValue.field.values[index].value

      var l = window.lodash
      var value = l.cloneDeep(this.props.selectedValue.value)

      if(event.target.checked) {
        value.selections = _.uniq(value.selections.concat(sel))
      } else {
        value.selections = _.reject(value.selections, (s) => s === sel)
      }

      this.props.onChange(value)
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
