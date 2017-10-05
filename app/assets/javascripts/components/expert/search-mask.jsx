(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.SearchMask = React.createClass({
    propTypes: {
    },








    _renderDependents(selectedValue) {

      if(!selectedValue.dependents) {
        return []
      }

      return selectedValue.dependents.map((dependent) => {
        return this._renderField(dependent, false)

      })

    },

    _renderCross(selectedValue, top) {

      if(!top) {
        return null;
      }

      return (
        <a onClick={(event) => this.props._onDeselect(event, selectedValue.field)} className='font-size-m link grey padding-inset-xs' data-placement='top' data-toggle='tooltip' data-type='remove-field' title='Dieses Feld beim Editieren von Gegenständen nicht mehr anzeigen'>
          <i className='fa fa-times-circle'></i>
        </a>

      )

    },


    _renderField(selectedValue, top) {

      var dependencyValue = _.first(this.props.selectedValues.filter((other) => {
        return other.field.id == selectedValue.field.values_dependency_field_id
      }))

      return (

        <div key={selectedValue.field.id} id={selectedValue.field.id}>
          <div className='white field row emboss padding-inset-xs margin-vertical-xxs margin-right-xs' data-editable='true' data-id='properties_ankunftsdatum' data-required='' data-type='field'>
            <div className='row'>
              <div className='col1of2 padding-vertical-xs' data-type='key'>

                {this._renderCross(selectedValue, top)}

                <strong className='font-size-m inline-block'>
                  {_jed(selectedValue.field.label) + (selectedValue.field.required ? ' *'  : '')}

                </strong>
              </div>

              {FieldSwitch._inputByType(selectedValue, this.props._onChangeSelectedValue, dependencyValue)}

            </div>
          </div>


          {this._renderDependents(selectedValue)}

        </div>
      )

    },










    _colLeftOrRight (leftOrRight) {

      return this.props.selectedValues.filter((selectedValue) => {
        return selectedValue.col == leftOrRight
      }).map((selectedValue) => {
        return (

          this._renderField(selectedValue, true)
        )
      })
    },


    _noFieldsChosen () {
      if(this.props.selectedValues.length == 0) {
        return (
          <h3 className='headline-s light padding-inset-m text-align-center' id='no-fields-message'>Keine Felder ausgewählt</h3>
        )
      } else {
        return null
      }

    },


    _colLeft () {
      return this._colLeftOrRight('left')
    },


    _colRight () {
      return this._colLeftOrRight('right')
    },


    render () {


      return (
        <div className='row margin-top-l padding-inset-m separated-bottom' style={{borderBottom: '0px'}}>
          <div className='row'>
            <FieldSelection
              _onSelect={this.props.onSelect}
              fields={this.props.fields}
              selectedValues={this.props.selectedValues}

            />
          </div>
          <form onSubmit={this.props.preventSubmit} className='row emboss deep margin-top-m padding-inset-s' id='field-selection'>
            {this._noFieldsChosen()}
            <div className='col1of2 padding-right-xs' id='field-form-left-side'>

              {this._colLeft()}

            </div>
            <div className='col1of2' id='field-form-right-side'>

              {this._colRight()}

            </div>
          </form>
        </div>
      )

    }
  })
})()
