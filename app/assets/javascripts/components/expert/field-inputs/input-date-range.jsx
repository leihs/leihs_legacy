(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputDateRange = window.createReactClass({
    propTypes: {
    },


    _onChangeFrom(date) {
      var l = window.lodash
      var value = l.cloneDeep(this.props.selectedValue.value)
      value.from = date
      this.props.onChange(value)
    },

    _onChangeTo(date) {
      var l = window.lodash
      var value = l.cloneDeep(this.props.selectedValue.value)
      value.to = date
      this.props.onChange(value)
    },


    render () {
      const props = this.props
      const selectedValue = props.selectedValue



      return (
        <div className='col1of2' data-type='value'>
          <div className='col1of2'>
            von:
            <DatePickerWithInput value={selectedValue.value.from} onChange={this._onChangeFrom} />
          </div>
          <div className='col1of2'>
            bis:
            <DatePickerWithInput value={selectedValue.value.to} onChange={this._onChangeTo} />
          </div>
        </div>
      )


    }
  })
})()
