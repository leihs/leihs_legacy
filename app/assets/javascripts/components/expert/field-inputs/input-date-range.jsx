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
      this.props.selectedValue.value.from = date
      this.props.onChange()
    },

    _onChangeTo(date) {
      this.props.selectedValue.value.to = date
      this.props.onChange()
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
