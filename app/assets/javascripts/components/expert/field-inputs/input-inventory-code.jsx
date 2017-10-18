(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputInventoryCode = React.createClass({
    propTypes: {
    },

    getInitialState() {
      return {
        selected: 'plusOne'
      }
    },

    _plusOne() {
      event.preventDefault()
      this.setState({selected: 'plusOne'})
      this.props.selectedValue.value.text = this.props.createItemProps.next_code
      this.props.onChange()
    },

    _fillGap() {
      event.preventDefault()
      this.setState({selected: 'fillGap'})
      this.props.selectedValue.value.text = this.props.createItemProps.lowest_code
      this.props.onChange()
    },

    _maximum() {
      event.preventDefault()
      this.setState({selected: 'maximum'})
      this.props.selectedValue.value.text = this.props.createItemProps.highest_code
      this.props.onChange()
    },

    _renderPlusOne() {
      return (null
      )
    },

    _renderFillGap() {
      return (null
      )
    },

    _renderMaximum() {
      return (null
      )
    },

    render () {

      const props = this.props
      const selectedValue = props.selectedValue

      var fieldClass = 'field row emboss padding-inset-xs margin-vertical-xxs margin-right-xs'
      if(this.props.error) {
        fieldClass += ' error'
      }
      if(selectedValue.hidden) {
        fieldClass += ' hidden'
      }

      return (
        <div className={fieldClass} data-editable='true' data-id='inventory_code' data-required='true' data-type='field'>
          <div className='row'>
            {RenderFieldLabel._renderFieldLabel(selectedValue.field, this.props.onClose)}
            <InputText selectedValue={selectedValue} onChange={this.props.onChange} />
          </div>

          <div className='row text-align-right' id='switch'>
            <button type='button' onClick={this._plusOne} className={'button small ' + (this.state.selected == 'plusOne' ? 'green' : 'white')}>
              {' zuletzt verwendet +1 '}
            </button>
            {' '}
            <button type='button' onClick={this._fillGap} className={'button small ' + (this.state.selected == 'fillGap' ? 'green' : 'white')}>
              {' Lücken auffüllen '}
            </button>
            {' '}
            <button type='button' onClick={this._maximum} className={'button small ' + (this.state.selected == 'maximum' ? 'green' : 'white')}>
              {' höchstmöglich '}
            </button>
          </div>
        </div>
      )
    }
  })
})()
