(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputCurrency = window.createReactClass({
    propTypes: {
    },


    _onChangeFrom(event) {
      event.preventDefault()
      this.props.selectedValue.value.from = event.target.value
      this.props.onChange()
    },

    _onChangeTo(event) {
      event.preventDefault()
      this.props.selectedValue.value.to = event.target.value
      this.props.onChange()
    },



    render () {
      const props = this.props
      const selectedValue = props.selectedValue

      return (
        <div className='col1of2' data-type='value'>
          <div className='col1of2'>
            min:
            <input autoComplete='off' className='width-full' type='text' value={selectedValue.value.from} onChange={this._onChangeFrom} />
          </div>
          <div className='col1of2'>
            max:
            <input autoComplete='off' className='width-full' type='text' value={selectedValue.value.to} onChange={this._onChangeTo} />
          </div>
        </div>
      )
    }
  })
})()
