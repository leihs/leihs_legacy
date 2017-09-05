(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.FieldSelection = React.createClass({
    propTypes: {
    },

    _onChange(result) {
      if(!result.id) {
        return
      }
      var field = _.find(this.props.fields, (field) => field.id == result.id)
      if(this.props._onSelect) {
        this.props._onSelect(field)
      }
    },


    _makeCall(term, callback) {
      callback(FieldsDropdownData._determineData(this.props.fields, this.props.selectedValues, term))
    },


    render () {
      const props = this.props


      return (
        <div className='col1of3'>
          <label className='row margin-bottom-xxs'>Feld auswählen</label>
          <FieldAutocompleteWrapper
            inputClassName='has-addon width-full ui-autocomplete-input'
            element='div'
            inputId='field-input'
            dropdownWidth='312px'
            label={null}
            _makeCall={this._makeCall}
            onChange={this._onChange}
            resetAfterSelection={true}
          />
        </div>
      )



    }
  })
})()
