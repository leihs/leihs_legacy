(() => {
  const React = window.React

  window.CreateModel = window.createReactClass({
    propTypes: {
    },

    createFieldModel(params) {
      var type = params.type
      var key = params.key
      var label = params.label
      var mandatory = params.mandatory

      var f = {
        type: type,
        key: key,
        label: label,
        mandatory: mandatory,
        specific: params.specific
      }

      var state = {}
      if(type == 'text' || type == 'textarea') {
        state = {text: ''}
      } else if(type == 'search-selections') {
        state = {term: '', selections: []}
      } else if(type == 'manufacturer') {
        state = {term: ''}
      } else if(type == 'accessories') {
        state = {text: '', accessories: []}
      } else if(type == 'images') {
        state = {nextId: 0, images: []}
      } else if(type == 'attachments') {
        state = {nextId: 0, attachments: []}
      } else if(type == 'properties') {
        state = {properties: []}
      }
      f.state = state
      return f
    },

    getInitialState () {
      return {
        fields: [

          this.createFieldModel({type: 'text', key: 'product', label: 'Product', mandatory: true}),
          this.createFieldModel({type: 'text', key: 'version', label: 'Version', mandatory: false}),

          this.createFieldModel({
            type: 'manufacturer',
            key: 'manufacturer',
            label: 'Manufacturer',
            mandatory: false,
            specific: {
              placeholder: '',
              search: (term, callback) => {

                var result = _.map(
                  _.filter(
                    this.props.manufacturers,
                    (m) => {
                      return m.toLowerCase().indexOf(term.toLowerCase()) > - 1
                    }
                  ),
                  (m, index) => {
                    return {
                      id: 'manufacturer_' + index,
                      label: m
                    }
                  }
                )

                callback(result)
              },
              onChange: (field, selected) => {

                this.updateState(
                  [
                    'fields',
                    _.findIndex(this.state.fields, (f) => field.key == f.key),
                    'state',
                    'term'
                  ],
                  selected.term
                )
              }
            }
          }),



          this.createFieldModel({type: 'text', key: 'description', label: 'Description', mandatory: false}),
          this.createFieldModel({type: 'textarea', key: 'technical_details', label: 'Technical Details', mandatory: false}),
          this.createFieldModel({type: 'text', key: 'internal_description', label: 'Internal Description', mandatory: false}),
          this.createFieldModel({type: 'text', key: 'hand_over_notes', label: 'Important notes for hand over', mandatory: false}),
          this.createFieldModel({
            type: 'search-selections',
            key: 'allocations',
            label: 'Allocations',
            mandatory: false,
            specific: {
              placeholder: _jed('Group'),
              search: (term, callback) => {
                this.getAjax(
                  '/manage/' + this.props.inventory_pool_id + '/groups?search_term=' + term,
                  {},
                  (data) => {
                    callback(
                      _.map(
                        data,
                        (d) => {
                          return {
                            id: d.id,
                            label: d.name
                          }
                        }
                      )
                    )
                  }
                )
              },
              onChange: (field, selected) => {

                if(!selected.id) {
                  return
                }

                if(_.find(field.state.selections, (s) => s.id == selected.id)) {
                  return
                }

                var id = selected.id
                var label = selected.term

                this.updateState(
                  [
                    'fields',
                    _.findIndex(this.state.fields, (f) => field.key == f.key),
                    'state',
                    'selections'
                  ],
                  field.state.selections.concat({
                    id: id,
                    label: label,
                    quantity: ''
                  })
                )

              }

            }
          }),

          this.createFieldModel({
            type: 'search-selections',
            key: 'categories',
            label: 'Categories',
            mandatory: false,
            specific: {
              placeholder: _jed('Category'),
              search: (term, callback) => {
                this.getAjax(
                  '/manage/' + this.props.inventory_pool_id + '/categories?search_term=' + term,
                  {},
                  (data) => {
                    callback(
                      _.map(
                        data,
                        (d) => {
                          return {
                            id: d.id,
                            label: d.name
                          }
                        }
                      )
                    )
                  }
                )
              },
              onChange: (field, selected) => {

                if(!selected.id) {
                  return
                }

                if(_.find(field.state.selections, (s) => s.id == selected.id)) {
                  return
                }

                var id = selected.id
                var label = selected.term

                this.updateState(
                  [
                    'fields',
                    _.findIndex(this.state.fields, (f) => field.key == f.key),
                    'state',
                    'selections'
                  ],
                  field.state.selections.concat({
                    id: id,
                    label: label
                  })
                )

              }
            }
          })
          ,

          this.createFieldModel({
            type: 'accessories',
            key: 'accessories',
            label: 'Accessories',
            mandatory: false
          })

          ,


          this.createFieldModel({
            type: 'search-selections',
            key: 'compatibles',
            label: 'Compatibles',
            mandatory: false,
            specific: {
              placeholder: _jed('Model'),
              search: (term, callback) => {
                this.getAjax(
                  '/manage/' + this.props.inventory_pool_id + '/models?search_term=' + term,
                  {},
                  (data) => {
                    callback(
                      _.map(
                        data,
                        (d) => {
                          return {
                            id: d.id,
                            label: d.product + (d.version ? ' ' + d.version : '')
                          }
                        }
                      )
                    )
                  }
                )
              },
              onChange: (field, selected) => {

                if(!selected.id) {
                  return
                }

                if(_.find(field.state.selections, (s) => s.id == selected.id)) {
                  return
                }

                var id = selected.id
                var label = selected.term

                this.updateState(
                  [
                    'fields',
                    _.findIndex(this.state.fields, (f) => field.key == f.key),
                    'state',
                    'selections'
                  ],
                  field.state.selections.concat({
                    id: id,
                    label: label
                  })
                )

              }
            }
          }),


          this.createFieldModel({type: 'images', key: 'images', label: 'Images', mandatory: false}),
          this.createFieldModel({type: 'attachments', key: 'attachments', label: 'Attachments', mandatory: false}),
          this.createFieldModel({type: 'properties', key: 'properties', label: 'Properties', mandatory: false}),
        ]
      }
    },

    fieldByKey(key) {

      return _.find(this.state.fields, (f) => f.key == key)

    },

    stateToRequest() {


      return {
        // NOTE: Rails unfortunately automatically wraps the parameters {model: {...}} if you dont do it,
        // which is confusing, but we do it anyways here explicitly.
        model: {
          type: 'model',
          product: this.fieldByKey('product').state.text,
          version: this.fieldByKey('version').state.text,
          manufacturer: this.fieldByKey('manufacturer').state.term,
          description: this.fieldByKey('description').state.text,
          technical_detail: this.fieldByKey('technical_details').state.text,
          internal_description: this.fieldByKey('internal_description').state.text,
          hand_over_note: this.fieldByKey('hand_over_notes').state.text,
          category_ids: _.map(this.fieldByKey('categories').state.selections, (s) => s.id),
          compatible_ids: _.map(this.fieldByKey('compatibles').state.selections, (s) => s.id),
          properties_attributes: _.map(
            _.filter(this.fieldByKey('properties').state.properties, (p) => !p.delete),
            (p) => {
              return {key: p.key, value: p.value}
            }
          ),
          partitions_attributes: _.object(_.map(
            this.fieldByKey('allocations').state.selections,
            (s, index) => {
              return [
                'rails_dummy_id_' + index,
                {
                  group_id: s.id,
                  quantity: s.quantity
                }
              ]
            }
          )),
          accessories_attributes: _.object(_.map(
            this.fieldByKey('accessories').state.accessories,
            (a, index) => {
              return [
                'rails_dummy_id_' + index,
                {
                  inventory_pool_toggle: (a.active ? '1' : '0') + ',' + this.props.inventory_pool_id,
                  name: a.label
                }
              ]
            }
          ))
        }
      }

    },


    hackyShowLoading() {
      var modal = new App.Modal($('<div></div>'))
      modal.undestroyable()
      App.Flash({
        type: 'notice',
        message: _jed('Uploading files - please wait'),
        loading: true
      }, 9999)
    },

    onSaveModelSuccess(response) {

      this.hackyHideFlash()

      this.hackyShowLoading()


      var modelId = response.id
      this.uploadFiles(modelId, (errors) => {
        if(errors.length == 0) {
          var flash = '?flash[success]=' + _jed('Model saved')
          window.location = this.props.inventory_path + flash

        } else {
          var message = _jed(
            '%s was saved, but there were problems uploading files',
            _jed('Model')
          )
          alert(message)

          window.location = '/manage/' + this.props.inventory_pool_id + '/models/' + modelId + '/edit'

        }
      })
    },

    onSaveModelError(response) {

      this.hackyShowFlash(response.responseText)

    },

    hackyShowFlash(message) {

      var flashContent = (
        <div className='paragraph-m row emboss straight text-align-center padding-inset-xs error'>
          <strong key='key1'>{message}</strong>
          <a key='key2' className='no-colors transparent-hover position-absolute-topright height-full padding-horizontal-m' data-remove='true' title='Hide notification'>
            <div className='table'>
              <div className='table-row'>
                <div className='table-cell vertical-align-middle'>
                  <i className='fa fa-times-circle'></i>
                </div>
              </div>
            </div>
          </a>
        </div>
      )

      var flash = document.getElementById('flash')
      flash.className = ''
      ReactDOM.render(flashContent, flash)
    },

    hackyHideFlash() {
      var flash = document.getElementById('flash')
      flash.className = 'hidden'
    },

    saveModel() {
      var data = this.stateToRequest()
      $.ajax({
        url: this.props.create_model_path,
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json',
        method: 'POST'
      }).done((response) => {
        this.onSaveModelSuccess(response)
      }).error((response) => {
        this.onSaveModelError(response)
      })
    },

    onClickSaveModel(event) {
      event.preventDefault()
      this.saveModel()
    },

    uploadPath(type) {
      if(type == 'image') {
        return this.props.store_image_path
      } else {
        return this.props.store_attachment_path
      }
    },


    uploadFile(type, modelId, file, callback) {

      var formData = new FormData()
      formData.append('data', file)
      formData.append('model_id', modelId)

      $.ajax({
        url: this.uploadPath(type),
        data: formData,
        contentType: false,
        method: 'POST',
        processData: false
      }).done((data) => {
        callback({result: 'success'})
      }).error((data) => {
        callback({result: 'failure'})
      })
    },

    fieldsByType(type) {
      return _.filter(
        this.state.fields,
        (f) => f.type == type
      )

    },

    uploadFiles(modelId, callback) {
      this.uploadImages(modelId, (errors1) => {
        this.uploadAttachments(modelId, (errors2) => {
          callback(errors1.concat(errors2))
        })
      })
    },

    uploadImages(modelId, callback) {
      var imageFields = this.fieldsByType('images')
      var files = _.flatten(_.map(
        imageFields,
        (f) => {
          return _.map(f.state.images, (img) => img.file)
        }
      ))

      this.uploadImagesRec('image', modelId, files, [], callback)
    },

    uploadAttachments(modelId, callback) {
      var attachmentFields = this.fieldsByType('attachments')
      var files = _.flatten(_.map(
        attachmentFields,
        (f) => {
          return _.map(f.state.attachments, (a) => a.file)
        }
      ))

      this.uploadImagesRec('attachment', modelId, files, [], callback)
    },


    uploadImagesRec(type, modelId, files, errors, callback) {
      if(files.length == 0) {
        callback(errors)
      } else {

        this.uploadFile(
          type,
          modelId,
          _.first(files),
          (result) => {

            var nextErrors = errors
            if(result.result != 'success') {
              nextErrors = errors.concat('error')
            }

            this.uploadImagesRec(
              type,
              modelId,
              _.rest(files),
              nextErrors,
              callback
            )

          }.bind(this)
        )

      }
    },

    renderHeader() {
      return (

        <div className='margin-top-l padding-horizontal-m'>
          <div className='row'>
            <div className='col1of2'>
              <h1 className='headline-l'>{_jed('Create new model')}</h1>
              <h2 className='headline-s light'>{_jed('Insert all required information')}</h2>
            </div>
            <div className='col1of2 text-align-right'>
              <a className='button grey' href='javascript:history.back()'>{_jed('Cancel')}</a>
              <button onClick={(e) => this.onClickSaveModel(e)} className='button green' id='save'>
                {_jed('Save %s', _jed('Model'))}
              </button>
            </div>
          </div>
        </div>

      )

    },


    leftFields() {
      return [
        'product',
        'version',
        'manufacturer',
        'description',
        'technical_details',
        'internal_description',
        'hand_over_notes',
        'allocations',
        'categories'
      ]
    },

    rightFields() {
      return [
        'images',
        'attachments',
        'accessories',
        'compatibles',
        'properties'
      ]
    },

    findFields(keys) {
      return _.map(
        keys,
        ((k) => {
          return _.find(this.state.fields, (f) => f.key == k)
        }).bind(this)
      )
    },

    renderFields(fields) {
      return _.map(
        fields,
        (f) => {
          return this.renderField(f)
        }
      )
    },

    renderLeftFields() {
      var leftFields = this.leftFields()
      var fields = this.findFields(leftFields)
      return this.renderFields(fields)
    },

    renderRightFields() {
      var rightFields = this.rightFields()
      var fields = this.findFields(rightFields)
      return this.renderFields(fields)
    },

    renderContent() {

      return (
        <div className='padding-inset-m'>
          <div className='row padding-top-s'>
            <form id='form'>
              <div className='col1of2 padding-right-xs'>
                {this.renderLeftFields()}
              </div>
              <div className='col1of2'>
                {this.renderRightFields()}
              </div>
            </form>

          </div>

        </div>

      )

    },

    cloneAndSet(obj, path, value) {
      if(path.length == 1) {
        var c = _.clone(obj)
        c[_.first(path)] = value
        return c
      } else {
        var c = _.clone(obj)
        c[_.first(path)] = this.cloneAndSet(obj[_.first(path)], _.rest(path), value)
        return c
      }
    },

    updateState(path, value) {
      this.setState((previous) => {
        return this.cloneAndSet(previous, path, value)
      })
    },

    renderTextInput(field) {

      var onChange = (event) => {
        var val = event.target.value

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'text'
          ],
          val
        )
      }
      return (
        <input onChange={(e) => onChange(e)} value={field.state.text} autoComplete='off' className='width-full' name='model[product]' type='text' />
      )
    },

    renderManufacturer(field) {
      return (
        <BasicAutocomplete
          inputClassName='has-addon width-full ui-autocomplete-input ui-autocomplete-loading'
          element='label'
          inputId={null}
          dropdownWidth='216px'
          label={field.specific.placeholder}
          _makeCall={(term, callback) => field.specific.search(term, callback)}
          onChange={(selected) => field.specific.onChange(field, selected)}
          term={field.state.term}
          initialText={field.state.term}
          name={null}
        />
      )

    },

    renderTextarea(field) {

      var onChange = (event) => {
        var val = event.target.value

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'text'
          ],
          val
        )
      }
      return (
        <textarea onChange={(e) => onChange(e)} value={field.state.text} autoComplete='off' className='width-full' name='model[technical_detail]' rows='6' type='text'></textarea>
      )
    },

    fileChooser: {},

    renderImages(field) {

      if(this.fileChooser[field.key]) {
        this.fileChooser[field.key].value = ''
      }

      var onClick = (event) => {
        event.preventDefault()
        this.fileChooser[field.key].click()
      }

      var onFileChange = (event) => {
        event.preventDefault()

        var file = event.target.files[0]

        var image = {
          type: 'new',
          id: field.state.nextId,
          filename: file.name,
          result: 'pending',
          file: file
        }

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'images'
          ],
          field.state.images.concat(image)
        )

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'nextId'
          ],
          field.state.nextId + 1
        )

        this.readURL(field, image)
      }

      return (
        <div className='row'>
          <div className='col1of3'></div>
          <div className='col2of3'>
            <button onClick={(e) => onClick(e)} className='button inset width-full' data-type='select'>{_jed('Select Image')}</button>
            <input ref={(ref) => this.fileChooser[field.key] = ref} onChange={(e) => onFileChange(e)} autoComplete='false' className='invisible height-full width-full position-absolute-topleft' type='file' />
          </div>
        </div>
      )


    },


    renderAttachments(field) {

      if(this.fileChooser[field.key]) {
        this.fileChooser[field.key].value = ''
      }

      var onClick = (event) => {
        event.preventDefault()
        this.fileChooser[field.key].click()
      }

      var onFileChange = (event) => {
        event.preventDefault()

        var file = event.target.files[0]

        var image = {
          type: 'new',
          id: field.state.nextId,
          filename: file.name,
          result: 'pending',
          file: file
        }

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'attachments'
          ],
          field.state.attachments.concat(image)
        )

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'nextId'
          ],
          field.state.nextId + 1
        )

      }

      return (
        <div className='row'>
          <div className='col1of3'></div>
          <div className='col2of3'>
            <button onClick={(e) => onClick(e)} className='button inset width-full' data-type='select'>{_jed('Select File')}</button>
            <input ref={(ref) => this.fileChooser[field.key] = ref} onChange={(e) => onFileChange(e)} autoComplete='false' className='invisible height-full width-full position-absolute-topleft' type='file' />
          </div>
        </div>
      )


    },

    renderProperties(field) {

      var onClick = (event) => {
        event.preventDefault()

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'properties'
          ],
          [{
            delete: false,
            key: '',
            value: ''
          }].concat(field.state.properties)
        )

      }

      return (
        <div className='text-align-right'>
          <button onClick={(e) => onClick(e)} className='button inset' id='add-property' type='button'>{_jed('Add %s', _jed('Property'))}</button>
        </div>
      )



    },

    renderAccessories(field) {

      var onChange = (event) => {

        var val = event.target.value

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'text'
          ],
          val
        )
      }

      var onClick = (event) => {
        event.preventDefault()

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'accessories'
          ],
          field.state.accessories.concat({
            active: true,
            label: field.state.text
          })
        )

        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'text'
          ],
          ''
        )

      }

      return (
        <div className='row text-align-right'>
          <div className='col4of5'>
            <input value={field.state.text} onChange={(e) => onChange(e)} autoComplete='off' className='width-full' id='accessory-name' placeholder={_jed('Name')} type='text' />
          </div>
          <div className='col1of5'>
            <button onClick={(e) => onClick(e)} className='button inset' id='add-accessory'>
              <i className='fa fa-plus'></i>
            </button>
          </div>
        </div>
      )

    },

    getAjax(url, data, callback) {
      $.ajax({
        url: url,
        contentType: 'application/json',
        dataType: 'json',
        method: 'GET',
        data: data
      }).done((data) => {
        callback(data)

      }).error((data) => {

      })
    },


    renderSearch(field) {



      return (
        <BasicAutocomplete
          inputClassName='has-addon width-full ui-autocomplete-input ui-autocomplete-loading'
          element='label'
          inputId={null}
          dropdownWidth='216px'
          label={field.specific.placeholder}
          _makeCall={(term, callback) => field.specific.search(term, callback)}
          onChange={(selected) => field.specific.onChange(field, selected)}
          resetAfterSelection={true}
          term={field.state.term}
          initialText={field.state.term}
          name={null}
        />
      )

    },

    renderInput(f) {


      if(f.type == 'text') {
        return this.renderTextInput(f)
      } else if(f.type == 'textarea') {
        return this.renderTextarea(f)
      } else if(f.type == 'search-selections') {
        return this.renderSearch(f)
      } else if(f.type == 'manufacturer') {
        return this.renderManufacturer(f)
      } else if(f.type == 'accessories') {
        return this.renderAccessories(f)
      } else if(f.type == 'images') {
        return this.renderImages(f)
      } else if(f.type == 'attachments') {
        return this.renderAttachments(f)
      } else if(f.type == 'properties') {
        return this.renderProperties(f)
      } else {
        return <div>TODO</div>
      }


    },


    readURL(field, image) {
        var reader = new FileReader();

        reader.onload = function (e) {
          var result = e.target.result

          var element = document.getElementById('field_' + field.key + '_image_' + image.id)
          if(element) {
            element.src = result
          }
        };

        reader.readAsDataURL(image.file);

    },


    renderAdditional(f) {


      if(f.type == 'properties') {

        return _.map(
          f.state.properties,
          (property, index) => {

            var onChangeKey = (event) => {
              var val = event.target.value

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'properties',
                  index,
                  'key'
                ],
                val
              )
            }

            var onChangeValue = (event) => {
              var val = event.target.value

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'properties',
                  index,
                  'value'
                ],
                val
              )
            }

            var onRemove = (event) => {
                event.preventDefault()

                this.updateState(
                  [
                    'fields',
                    _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                    'state',
                    'properties',
                    index,
                    'delete'
                  ],
                  !property.delete
                )
            }

            var renderButton = () => {
              if(property.delete) {
                return (
                  <button onClick={(e) => onRemove(e)} className='button small inset' data-remove='' title={_jed('Undo')}>{_jed('Undo')}</button>
                )
              } else {
                return (
                  <button onClick={(e) => onRemove(e)} className='button small inset' data-remove='' title={_jed('Remove')}>{_jed('Remove')}</button>
                )
              }
            }

            var renderTrash = () => {
              if(property.delete) {
                return <i className='fa fa-trash'></i>
              } else {
                return null
              }
            }

            return (
              <div key={'property_' + index} className='row line font-size-xs focus-hover-thin' data-type='inline-entry' date-new=''>
                <div className='line-col col1of10 text-align-left no-padding text-align-center cursor-move' data-type='sort-handle'>
                  {renderTrash()}
                </div>
                <div className='line-col col4of10 no-padding'>
                  <input onChange={(e) => onChangeKey(e)} value={property.key} className='small width-full' name='model[properties_attributes][][key]' type='text' />
                </div>
                <div className='line-col col4of10'>
                  <input onChange={(e) => onChangeValue(e)} value={property.value} className='small width-full' name='model[properties_attributes][][value]' type='text' />
                </div>
                <div className='line-col col1of10 text-align-right'>
                  {renderButton()}
                </div>
              </div>
            )
          }
        )
      }

      else if(f.type == 'images') {

        return _.map(
          f.state.images,
          (image, index) => {

            var onRemove = (event) => {
              event.preventDefault()

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'images'
                ],
                _.reject(f.state.images, (si) => si.id == image.id)
              )

            }


            return (

              <div key={'image_' + image.id} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
                <div className='line-col col1of10 text-align-center' title='File has to be uploaded on save'>
                  <i className='fa fa-cloud-upload'></i>
                </div>
                <div className='line-col col1of10 text-align-center'>
                  <img id={'field_' + f.key + '_image_' + image.id} className='max-height-xxs max-width-xxs' src={null} />
                </div>
                <div className='line-col col5of10 text-align-left' style={{wordBreak: 'break-all'}}>
                  {image.filename}
                </div>
                <div className='line-col col3of10 text-align-right'>
                  <button onClick={(e) => onRemove(e)} className='button small inset' data-remove='' type='button'>{_jed('Remove')}</button>
                </div>
              </div>

            )




          }
        )




      }


      else if(f.type == 'attachments') {

        return _.map(
          f.state.attachments,
          (attachment, index) => {

            var onRemove = (event) => {
              event.preventDefault()

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'attachments'
                ],
                _.reject(f.state.attachments, (si) => si.id == attachment.id)
              )

            }


            return (

              <div key={'attachment_' + attachment.id} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
                <div className='line-col col1of10 text-align-center' title='File has to be uploaded on save'>
                  <i className='fa fa-cloud-upload'></i>
                </div>
                <div className='line-col col6of10 text-align-left' style={{wordBreak: 'break-all'}}>
                  {attachment.filename}
                </div>
                <div className='line-col col3of10 text-align-right'>
                  <button onClick={(e) => onRemove(e)} className='button small inset' data-remove='' type='button'>{_jed('Remove')}</button>
                </div>
              </div>

            )




          }
        )




      }



      else if(f.type == 'accessories') {

        return _.map(
          f.state.accessories,
          (a, index) => {

            var onChange = (event) => {
              var val = event.target.checked
              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'accessories',
                  index,
                  'active'
                ],
                val
              )
            }

            var onClick = (event) => {
              event.preventDefault()

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'accessories'
                ],
                _.reject(f.state.accessories, (ai, i) => i == index)
              )
            }

            return (
              <div key={'accessory_' + index} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
                <label className='line-col col1of10 text-align-center no-padding'>
                  <input onChange={(e) => onChange(e)} checked={a.active} autoComplete='off' name='model[accessories_attributes][uid1][inventory_pool_toggle]' type='checkbox' />
                </label>
                <div className='line-col col6of10 text-align-left'>
                  {a.label}
                </div>
                <div className='line-col col3of10 text-align-right'>
                  <button onClick={(e) => onClick(e)} className='button small inset' data-remove=''>{_jed('Remove')}</button>
                </div>
              </div>
            )


          }

        )

      }

      else if(f.type == 'search-selections') {
        return _.map(
          f.state.selections,
          (s, index) => {

            var onChange = (event) => {
              var val = event.target.value
              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'selections',
                  index,
                  'quantity'
                ],
                val
              )
            }

            var onRemove = (event) => {
              event.preventDefault()
              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'selections'
                  // index,
                  // 'quantity'
                ],
                _.reject(f.state.selections, (si) => si.id == s.id)
              )
            }


            if(f.key == 'allocations') {
              return (
                <div key={s.id} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
                  <div className='line-col col3of5 text-align-left' data-name='AV-Techniker'>
                    {s.label}
                  </div>
                  <div className='line-col col1of5 text-align-center'>
                    <input value={s.quantity} onChange={(e) => onChange(e)} autoComplete='off' className='width-xs small text-align-center' name='model[partitions_attributes][uid23][quantity]' type='text' />
                  </div>
                  <div className='line-col col1of5 text-align-right'>
                    <button onClick={(e) => onRemove(e)} className='button small inset'>
                      {_jed('Remove')}
                    </button>
                  </div>
                </div>
              )
            } else {

              return (
                <div key={s.id} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
                  <div className='line-col col2of3 text-align-left'>
                    {s.label}
                  </div>
                  <div className='line-col col1of3 text-align-right'>
                    <button onClick={(e) => onRemove(e)} className='button small inset' data-remove=''>
                      {_jed('Remove')}
                    </button>
                  </div>
                </div>
              )

            }


          }
        )
      } else {
        return null
      }

    },


    renderField(f) {

      var renderLabel = () => _jed(f.label)
      var renderMandatory = () => (f.mandatory ? ' *' : null)

      return (

        <div key={f.key} id={f.key} className='field row emboss margin-vertical-xxs margin-right-xs'>
          <div className='row padding-inset-xs'>
            <div className='col1of2 padding-vertical-xs'>
              <strong className='font-size-m inline-block'>
                {renderLabel()}
                {renderMandatory()}
              </strong>
            </div>
            <div className='col1of2'>
              {this.renderInput(f)}
            </div>
          </div>
          <div className={'list-of-lines even padding-bottom-xxs' + (f.key == 'properties' ? ' ui-sortable' : '')}>
            {this.renderAdditional(f)}
          </div>
        </div>
      )
    },

    render () {
      return (
        <div className='row content-wrapper min-height-xl min-width-full straight-top'>
          {this.renderHeader()}
          {this.renderContent()}
        </div>
      )
    }
  })
})()
