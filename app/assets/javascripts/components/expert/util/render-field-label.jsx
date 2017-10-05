window.RenderFieldLabel = {

  _renderFieldLabelText(field) {
    if(field.required) {
      return _jed(field.label) + ' *'
    } else {
      return _jed(field.label)
    }

  },

  _renderFieldLabel(field) {
    return (
      <div className='col1of2 padding-vertical-xs' data-type='key'>

        <strong className='font-size-m inline-block'>
          {this._renderFieldLabelText(field)}
        </strong>
      </div>

    )

  }

}
