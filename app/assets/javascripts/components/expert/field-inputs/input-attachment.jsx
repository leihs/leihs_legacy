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
        type: 'new',
        file: file,
        result: 'pending'
      })

      this.props.onChange()
    },

    _renderFileRows() {
      // debugger
      return this.props.selectedValue.value.fileModels.map((fileModel, index) => {
        return (
          this._renderFileRow(fileModel, index)
        )
      })

    },

    _undoRemove(index) {

      var fileModels = this.props.selectedValue.value.fileModels
      fileModels[index].delete = false

      this.props.onChange()
    },

    _removeNewFile(index) {

      var fileModels = this.props.selectedValue.value.fileModels
      if(fileModels[index].type == 'new') {
        this.props.selectedValue.value.fileModels.splice(index, 1)
      } else {
        fileModels[index].delete = true
      }


      this.props.onChange()
    },

    _renderFilename(fileModel) {
      return (
        <a className='blue' href={fileModel.public_filename} target='_blank'>
          {fileModel.filename}
        </a>
      )
    },

    _renderUploadIcon(fileModel) {

      return (
        <div className='line-col text-align-center' title='Datei wird beim speichern hochgeladen'>
          <i className='fa fa-cloud-upload'></i>
        </div>
      )
    },


    _renderDeleteIcon(fileModel) {

      if(fileModel.delete) {
        return (
          <div className='line-col text-align-center' title='Datei wird beim speichern hochgeladen'>
            <i className='fa fa-trash'></i>
          </div>
        )
      } else {
        return null
      }
    },


    _renderDeleteButton(fileModel, index) {

      if(fileModel.delete) {
        return (
          <button onClick={(event) => this._undoRemove(index)} className='button small inset' data-remove='' type='button'>
            Undo
          </button>
        )

      } else {
        return (
          <button onClick={(event) => this._removeNewFile(index)} className='button small inset' data-remove='' type='button'>
            Entfernen
          </button>
        )
      }


    },

    _renderFileRow(fileModel, index) {

      if(fileModel.type == 'new') {

        return (
          <div key={'key_' + index} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
            {this._renderUploadIcon(fileModel)}
            <div className='line-col col7of10 text-align-left'>
              {fileModel.file.name}
            </div>
            <div className='line-col col3of10 text-align-right'>
              <button onClick={(event) => this._removeNewFile(index)} className='button small inset' data-remove='' type='button'>
                Entfernen
              </button>
            </div>
          </div>
        )



      } else if(fileModel.type == 'edit') {

        var klass = 'row line font-size-xs focus-hover-thin'
        if(fileModel.delete) {
          klass += ' striked'
        }

        return (
          <div key={'key_' + index} className={klass} data-new='' data-type='inline-entry'>
            {this._renderDeleteIcon(fileModel)}
            <div className='line-col col7of10 text-align-left'>
              {this._renderFilename(fileModel)}
            </div>
            <div className='line-col col3of10 text-align-right'>
              {this._renderDeleteButton(fileModel, index)}
            </div>
          </div>
        )


      } else {
        throw 'Not implemented for type: ' + fileModel.type
      }

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
