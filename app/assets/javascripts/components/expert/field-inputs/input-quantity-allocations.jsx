(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputQuantityAllocations = React.createClass({
    propTypes: {
    },

    _undoRemoveAllocation(event, index) {
      event.preventDefault()


      var allocation = this.props.selectedValue.value.allocations[index];
      allocation.deleted = false
      this.props.onChange()
    },


    _removeAllocation(event, index) {
      event.preventDefault()


      var allocation = this.props.selectedValue.value.allocations[index];
      if(allocation.type == 'new') {
        var allocations = this.props.selectedValue.value.allocations
        this.props.selectedValue.value.allocations.splice(index, 1)
        this.props.onChange()
      } else {
        allocation.deleted = true
        this.props.onChange()
      }


    },


    _addAllocation(event) {
      event.preventDefault()

      this.props.selectedValue.value.allocations = [
        {
          quantity: '',
          location: '',
          type: 'new'
        }
      ].concat(this.props.selectedValue.value.allocations)

      this.props.onChange()
    },

    _onChangeQuantity(event, index) {
      event.preventDefault()
      this.props.selectedValue.value.allocations[index].quantity = event.target.value
      this.props.onChange()

    },

    _onChangeLocation(event, index) {
      event.preventDefault()
      this.props.selectedValue.value.allocations[index].location = event.target.value
      this.props.onChange()
    },


    _renderRow(allocation, index) {

      if(allocation.deleted) {


        return (
          <div key={'key_' + index} className='row line font-size-xs focus-hover-thin striked' data-type='inline-entry'>
           <div className='line-col' title='Wird beim speichern entfernt'>
              <i className='fa fa-trash'></i>
           </div>
           <div className='line-col col1of10 text-align-center'>Quantity:</div>
           <div className='line-col col2of10'>
             <input onChange={(event) => this._onChangeQuantity(event, index)} value={allocation.quantity} className='width-full small text-align-center' data-quantity-allocation='true' name='item[properties][quantity_allocations][][quantity]' type='text' />
           </div>
           <div className='line-col col1of10 text-align-center'>Location:</div>
           <div className='line-col col5of10'>
             <input onChange={(event) => this._onChangeLocation(event, index)} value={allocation.location} className='width-full small text-align-center' data-room-allocation='true' name='item[properties][quantity_allocations][][room]' type='text' />
           </div>
           <div className='line-col col1of10'>
             <button onClick={(event) => this._undoRemoveAllocation(event, index)} className='button inset small' data-remove=''>rückgängig</button>
           </div>
        </div>
        )




      } else {
        return (
          <div key={'key_' + index} className='row line font-size-xs focus-hover-thin' data-type='inline-entry'>
            <div className='line-col col1of10 text-align-center'>Quantity:</div>
            <div className='line-col col2of10'>
              <input onChange={(event) => this._onChangeQuantity(event, index)} value={allocation.quantity} className='width-full small text-align-center' data-quantity-allocation='true' name='item[properties][quantity_allocations][][quantity]' type='text' />
            </div>
            <div className='line-col col1of10 text-align-center'>Location:</div>
            <div className='line-col col5of10'>
              <input onChange={(event) => this._onChangeLocation(event, index)} value={allocation.location} className='width-full small text-align-center' data-room-allocation='true' name='item[properties][quantity_allocations][][room]' type='text' />
            </div>
            <div className='line-col col1of10'>
              <button onClick={(event) => this._removeAllocation(event, index)} className='button inset small' data-remove=''>Remove</button>
            </div>
          </div>
        )
      }
    },

    _renderRows() {

      return this.props.selectedValue.value.allocations.map((allocation, index) => {
        return (
          this._renderRow(allocation, index)
        )
      })

    },


    _allocatedQuantity() {


      var allocations = this.props.selectedValue.value.allocations

      var nans = _.filter(allocations, (a) => {
        return a.quantity != '' && isNaN(parseInt(a.quantity))
      })

      if(nans.length > 0) {
        return NaN
      }


      return _.reduce(allocations, (result, a) => {
        var value = 0
        if(a.quantity != '') {
          value = parseInt(a.quantity)
        }
        return result + value
      }, 0)

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


      var totalText = this.props.dataDependency.value.text
      var total = 0
      if(totalText != '') {
        total = parseInt(totalText)
      }
      var allocatedQuantity = this._allocatedQuantity()

      var validNumbers = !isNaN(total) && !isNaN(allocatedQuantity)

      var remainingText = 'invalid numbers'
      if(validNumbers) {
        remainingText = _jed('remaining') + ' ' + (total - allocatedQuantity)
      }


      return (

        <div className={fieldClass} data-editable='true' data-id='properties_quantity_allocations' data-required='' data-type='field'>
          <div className='row'>
            {RenderFieldLabel._renderFieldLabel(selectedValue.field, this.props.onClose)}


            <div className='col1of2' data-type='value'>

              <div className='row'>
                <div className='col7of8 padding-vertical-xs' id='remaining-total-quantity'>{remainingText}</div>
                <div className='col1of8'>
                  <button onClick={this._addAllocation} className='button inset float-right' id='add-inline-entry'>
                    <i className='fa fa-plus'></i>
                  </button>
                </div>
              </div>


            </div>


          </div>


          <div className='list-of-lines even'>
            {this._renderRows()}
          </div>
        </div>

      )
    }
  })
})()
