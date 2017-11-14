window.RenderFieldLabel = {

  _renderFieldLabelText(field) {
    if(field.required) {
      return _jed(field.label) + ' *'
    } else {
      return _jed(field.label)
    }

  },

  _renderFieldLabel(field, onClose) {

    var closeIcon = null

    if(!field.required && !field.visibility_dependency_field_id) {
      closeIcon = (
        <a onClick={onClose} className='font-size-m link grey padding-inset-xs' data-placement='top' data-toggle='tooltip' data-type='remove-field' title='Dieses Feld beim Editieren von Gegenständen nicht mehr anzeigen'>
          <i className='fa fa-times-circle'></i>
        </a>
      )
    }

    return (
      <div className='col1of2 padding-vertical-xs' data-type='key'>

        {closeIcon}

        <strong className='font-size-m inline-block'>
          {this._renderFieldLabelText(field)}
        </strong>
      </div>

    )

  }

}
