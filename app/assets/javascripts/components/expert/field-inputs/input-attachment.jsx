(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputAttachment = React.createClass({
    propTypes: {
    },


    _onFileChange(event) {
      event.preventDefault()

      var file = event.target.files[0];
      this.props.selectedValue.value.fileModels.push({
        file: file,
        result: 'pending'
      })

      this.props.onChange()
    },

    _renderFileRows() {

      return this.props.selectedValue.value.fileModels.map((fileModel, index) => {
        return (
          this._renderFileRow(fileModel, index)
        )
      })

    },

    _removeFile(index) {

      this.props.selectedValue.value.fileModels.splice(index, 1)

      this.props.onChange()
    },

    _renderFileRow(fileModel, index) {

      return (
        <div key={'key_' + index} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
          <div className='line-col text-align-center' title='Datei wird beim speichern hochgeladen'>
            <i className='fa fa-cloud-upload'></i>
          </div>
          <div className='line-col col7of10 text-align-left'>
            {fileModel.file.name}
          </div>
          <div className='line-col col3of10 text-align-right'>
            <button onClick={(event) => this._removeFile(index)} className='button small inset' data-remove='' type='button'>
              Entfernen
            </button>
          </div>
        </div>
      )

    },

    render () {
      const props = this.props
      const selectedValue = props.selectedValue

      // Make sure input element is cleared always, otherwise you cannot add the same file twice.
      if(this.inputElement) {
        this.inputElement.value = ''
      }


      var fieldClass = 'field row emboss padding-inset-xs margin-vertical-xxs margin-right-xs'
      if(this.props.error) {
        fieldClass += ' error'
      }
      if(selectedValue.hidden) {
        fieldClass += ' hidden'
      }

      return (

        <div className={fieldClass} data-editable='true' data-id='attachments' data-required='' data-type='field'>
          <div className='row'>
            {RenderFieldLabel._renderFieldLabel(selectedValue.field, this.props.onClose)}

            <div className='col1of2' data-type='value'>
              <button onClick={(event) => this.inputElement.click()} type='button' className='button inset width-full' data-type='select'>
                Datei auswählen
              </button>
              <input ref={(input) => this.inputElement = input} onChange={this._onFileChange} autoComplete='false' className='invisible height-full width-full position-absolute-topleft' type='file' />
            </div>


          </div>


          <div className='list-of-lines even padding-bottom-xxs'>
            {this._renderFileRows()}
          </div>
        </div>

      )
    }
  })
})()
