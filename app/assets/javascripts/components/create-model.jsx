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
      var disabled = params.disabled

      var f = {
        type: type,
        key: key,
        label: label,
        mandatory: mandatory,
        disabled: disabled,
        specific: params.specific
      }

      var state = {}
      if(type == 'text' || type == 'textarea' || type == 'software_information') {
        state = {text: params.text}
      } else if(type == 'search-selections') {
        state = {term: '', selections: params.selections}
      } else if(type == 'manufacturer') {
        state = {term: params.manufacturer}
      } else if(type == 'accessories') {
        state = {text: '', accessories: params.accessories}
      } else if(type == 'images') {
        state = {nextId: 0, images: params.images}
      } else if(type == 'attachments') {
        state = {nextId: 0, attachments: params.attachments}
      } else if(type == 'properties') {
        state = {properties: params.properties}
      } else if(type == 'checkbox') {
        state = {checked: params.checked}
      }
      f.state = state
      return f
    },

    getInitialState () {

      var edit = (this.props.edit_data ? true : false)
      var model = null
      if(edit) {
        model = this.props.edit_data.model
      }

      var product = () => {
        if(edit) {
          return model.product
        } else {

        }
      }


      if(this.props.type == 'software') {

        return {

          fields: [

            this.createFieldModel({
              type: 'text',
              key: 'product',
              label: 'Product',
              mandatory: true,

              text: (edit ? model.product || '' : '')
            }),

            this.createFieldModel({
              type: 'text',
              key: 'version',
              label: 'Version',
              mandatory: false,

              text: (edit ? model.version || '' : '')
            }),

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
              },

              manufacturer: (edit ? model.manufacturer || '' : '')
            }),


            this.createFieldModel({
              type: 'software_information',
              key: 'software_information',
              label: 'Software Information',
              mandatory: false,

              text: (edit ? model.technical_detail || '' : '')
            }),

            this.createFieldModel({
              type: 'attachments',
              key: 'attachments',
              label: 'Attachments',
              mandatory: false,

              attachments: (edit ? _.map(
                this.props.edit_data.attachments,
                (a) => {
                  return {
                    delete: false,
                    id: a.id,
                    filename: a.filename,
                    type: 'existing'
                  }
                }
              ) : [])
            })

          ]


        }




      }



      return {
        fields: [

          this.createFieldModel({
            type: 'text',
            key: 'product',
            label: 'Product',
            mandatory: true,

            text: (edit ? model.product || '' : '')
          }),

          this.createFieldModel({
            type: 'checkbox',
            key: 'is_package',
            label: 'this is a package',
            mandatory: false,
            disabled: edit,

            checked: (edit ? model.is_package : false)
          }),

          this.createFieldModel({
            type: 'text',
            key: 'version',
            label: 'Version',
            mandatory: false,

            text: (edit ? model.version || '' : '')
          }),

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
            },

            manufacturer: (edit ? model.manufacturer || '' : '')
          }),



          this.createFieldModel({
            type: 'textarea',
            key: 'description',
            label: 'Description',
            mandatory: false,

            text: (edit ? model.description || '' : '')
          }),

          this.createFieldModel({
            type: 'textarea',
            key: 'technical_details',
            label: 'Technical Details',
            mandatory: false,

            text: (edit ? model.technical_detail || '' : '')
          }),

          this.createFieldModel({
            type: 'textarea',
            key: 'internal_description',
            label: 'Internal Description',
            mandatory: false,

            text: (edit ? model.internal_description || '' : '')
          }),

          this.createFieldModel({
            type: 'textarea',
            key: 'hand_over_notes',
            label: 'Important notes for hand over',
            mandatory: false,

            text: (edit ? model.hand_over_note || '' : '')
          }),

          this.createFieldModel({
            type: 'search-selections',
            key: 'allocations',
            label: 'Allocations',
            mandatory: false,
            specific: {
              placeholder: _jed('Entitlement-Group'),
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

                if(_.find(field.state.selections, (s) => s.group_id == selected.id)) {
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
                  [{
                    group_id: id,
                    label: label,
                    quantity: '1'
                  }].concat(field.state.selections)
                )

              }

            },

            selections: (edit ? _.map(
              this.props.edit_data.allocations,
              (a) => {
                return {
                  id: a.id,
                  group_id: a.group_id,
                  quantity: a.quantity,
                  label: a.label,
                  delete: false
                }
              }

            ) : [])
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
            },

            selections: (edit ? _.map(
              this.props.edit_data.categories,
              (c) => {
                return {
                  id: c.id,
                  label: c.label,
                  delete: false
                }
              }

            ) : [])

          })
          ,

          this.createFieldModel({
            type: 'accessories',
            key: 'accessories',
            label: 'Accessories',
            mandatory: false,

            accessories: (edit ? _.map(
              this.props.edit_data.accessories,
              (a) => {
                var l = window.lodash
                return {
                  delete: false,
                  active: l.includes(a.inventory_pool_ids, this.props.inventory_pool_id),
                  label: a.name,
                  id: a.id
                }
              }
            ) : [])
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
            },

            selections: (edit ? _.map(
              this.props.edit_data.compatibles,
              (c) => {
                return {
                  id: c.id,
                  label: c.label,
                  delete: false
                }
              }
            ) : [])


          }),


          this.createFieldModel({
            type: 'images',
            key: 'images',
            label: 'Images',
            mandatory: false,

            images: (edit ? _.map(
              this.props.edit_data.images,
              (i) => {
                return {
                  delete: false,
                  id: i.id,
                  filename: i.filename,
                  type: 'existing'
                }
              }
            ) : [])
          }),

          this.createFieldModel({
            type: 'attachments',
            key: 'attachments',
            label: 'Attachments',
            mandatory: false,

            attachments: (edit ? _.map(
              this.props.edit_data.attachments,
              (a) => {
                return {
                  delete: false,
                  id: a.id,
                  filename: a.filename,
                  type: 'existing'
                }
              }
            ) : [])
          }),

          this.createFieldModel({
            type: 'properties',
            key: 'properties',
            label: 'Properties',
            mandatory: false,

            properties: (edit ? _.map(
              this.props.edit_data.properties,
              (p) => {
                return {
                  delete: false,
                  key: p.key,
                  value: p.value,
                  type: 'existing'
                }
              }
            ) : [])




          })
        ]
      }
    },

    fieldByKey(key) {

      return _.find(this.state.fields, (f) => f.key == key)

    },

    stateToRequest() {

      if(this.props.type == 'software') {

        return {
          // NOTE: Rails unfortunately automatically wraps the parameters {model: {...}} if you dont do it,
          // which is confusing, but we do it anyways here explicitly.
          model: {
            type: 'software',
            product: this.fieldByKey('product').state.text,
            version: this.fieldByKey('version').state.text,
            manufacturer: this.fieldByKey('manufacturer').state.term,
            technical_detail: this.fieldByKey('software_information').state.text,
            attachments_attributes: _.object(
              _.map(
                _.reject(this.fieldByKey('attachments').state.attachments, (i) => i.type == 'new'),
                (a, index) => {

                  return [
                    a.id,
                    {
                      id: a.id,
                      _destroy: (a.delete ? '1' : null)
                    }

                  ]


                }
              )
            )

          }
        }


      }

      var m = {
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
          category_ids: _.map(_.reject(this.fieldByKey('categories').state.selections, (s) => s.delete), (s) => s.id),
          compatible_ids: _.map(_.reject(this.fieldByKey('compatibles').state.selections, (s) => s.delete), (s) => s.id),
          properties_attributes: _.map(
            _.filter(this.fieldByKey('properties').state.properties, (p) => !p.delete),
            (p) => {
              return {key: p.key, value: p.value}
            }
          ),
          partitions_attributes: _.object(_.map(
            this.fieldByKey('allocations').state.selections,
            (s, index) => {

              if(!s.id) {
                return [
                  'rails_dummy_id_' + index,
                  {
                    group_id: s.group_id,
                    quantity: s.quantity
                  }
                ]
              } else {
                return [
                  s.id,
                  {
                    id: s.id,
                    group_id: s.group_id,
                    quantity: s.quantity,
                    _destroy: (s.delete ? true : null)
                  }
                ]
              }

            }
          )),
          accessories_attributes: _.object(_.map(
            this.fieldByKey('accessories').state.accessories,
            (a, index) => {

              if(a.id) {
                return [
                  a.id,
                  {
                    id: a.id,
                    inventory_pool_toggle: (a.active ? '1' : '0') + ',' + this.props.inventory_pool_id,
                    _destroy: (a.delete ? true : null)
                  }
                ]

              } else {
                return [
                  'rails_dummy_id_' + index,
                  {
                    inventory_pool_toggle: (a.active ? '1' : '0') + ',' + this.props.inventory_pool_id,
                    name: a.label
                  }
                ]

              }

            }
          )),

          images_attributes: _.object(
            _.map(
              _.reject(this.fieldByKey('images').state.images, (i) => i.type == 'new'),
              (i, index) => {

                return [
                  i.id,
                  {
                    id: i.id,
                    _destroy: (i.delete ? '1' : null)
                  }

                ]


              }
            )
          )
          ,

          attachments_attributes: _.object(
            _.map(
              _.reject(this.fieldByKey('attachments').state.attachments, (i) => i.type == 'new'),
              (a, index) => {

                return [
                  a.id,
                  {
                    id: a.id,
                    _destroy: (a.delete ? '1' : null)
                  }

                ]


              }
            )
          )

        }
      }

      if(!this.isEdit()) {
        m.model.is_package = this.fieldByKey('is_package').state.checked
      }

      return m
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

      if(this.flatImageFiles().concat(this.flatAttachments()).length > 0) {
        this.hackyShowLoading()
      }


      var modelId = response.id
      this.uploadFiles(modelId, (errors) => {
        if(errors.length == 0) {
          var flash = '?flash[success]=' + _jed('Model saved')
          var allModels = ''
          if(!this.isEdit()) {
            allModels = '&filters=all_models'
          }
          window.location = this.props.inventory_path + flash + allModels

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
        url: (this.isEdit() ? (this.props.create_model_path + '/' + this.props.edit_data.model.id) : this.props.create_model_path),
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json',
        method: (this.isEdit() ? 'PUT' : 'POST')
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

    flatImageFiles() {
      var imageFields = this.fieldsByType('images')
      return _.flatten(_.map(
        imageFields,
        (f) => {
          return _.map(_.reject(f.state.images, (img) => img.type == 'existing'), (img) => img.file)
        }
      ))
    },

    uploadImages(modelId, callback) {
      var files = this.flatImageFiles()
      this.uploadImagesRec('image', modelId, files, [], callback)
    },

    flatAttachments() {
      var attachmentFields = this.fieldsByType('attachments')
      return _.flatten(_.map(
        attachmentFields,
        (f) => {
          return _.map(_.reject(f.state.attachments, (a) => a.type == 'existing'), (a) => a.file)
        }
      ))
    },

    uploadAttachments(modelId, callback) {
      var files = this.flatAttachments()
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

    isEdit() {
      return (this.props.edit_data ? true : false)
    },

    title() {
      if(this.props.type == 'software') {
        if(this.isEdit()) {
          return _jed('Edit Software')
        } else {
          return _jed('Create new software')
        }

      } else {
        if(this.isEdit()) {
          return _jed('Edit Model')
        } else {
          return _jed('Create new model')
        }
      }

    },

    hint() {
      if(this.isEdit()) {
        return _jed('Make changes and save')
      } else {
        return _jed('Insert all required information')
      }
    },

    renderHeader() {
      return (

        <div className='margin-top-l padding-horizontal-m'>
          <div className='row'>
            <div className='col1of2'>
              <h1 className='headline-l'>{this.title()}</h1>
              <h2 className='headline-s light'>{this.hint()}</h2>
            </div>
            <div className='col1of2 text-align-right'>
              <a className='button grey' href='javascript:history.back()'>{_jed('Cancel')}</a>
              <button onClick={(e) => this.onClickSaveModel(e)} className='button green' id='save'>
                {_jed('Save %s', (this.props.type == 'software' ? _jed('Software') : _jed('Model')))}
              </button>
            </div>
          </div>
        </div>

      )

    },


    leftFields() {

      if(this.props.type == 'software') {
        return [
          'product',
          'version',
          'manufacturer'
        ]
      }

      return [
        'product',
        'is_package',
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

      if(this.props.type == 'software') {
        return [
          'software_information',
          'attachments'
        ]
      }

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

    renderCheckbox(field) {

      var onChange = (event) => {
        var val = event.target.checked
        this.updateState(
          [
            'fields',
            _.findIndex(this.state.fields, (f) => field.key == f.key),
            'state',
            'checked'
          ],
          val
        )
      }

      return (
        <div className='padding-vertical-xs'>
          <input onChange={(e) => onChange(e)} disabled={(field.disabled ? 'disabled': null)} checked={field.state.checked} type='checkbox'  />
        </div>
      )

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

    renderSoftwareInformation(field) {

      return this.renderTextarea(field)

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

      // if(field.key == 'software_information' || field.key == 'technical_details' || field.key == 'internal_description' || field.key == 'hand_over_notes' || field.key == 'description') {
        return (
          <AutosizeTextarea refkey={field.key} onChange={(e) => onChange(e)} value={field.state.text} autoComplete='off' className='width-full' name='model[technical_detail]' rows='6' type='text' />
        )
      // } else {
      //   return (
      //     <textarea onChange={(e) => onChange(e)} value={field.state.text} autoComplete='off' className='width-full' name='model[technical_detail]' rows='6' type='text'></textarea>
      //   )
      // }

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
      } else if(f.type == 'software_information') {
        return this.renderSoftwareInformation(f)
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
      } else if(f.type == 'checkbox') {
        return this.renderCheckbox(f)
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


    _technicalDetailLines(text) {
      return text.split('\r\n')
    },

    _technicalDetailLinesWithLinks(text) {
      return _.filter(this._technicalDetailLines(text), (line) => {
        return this._lineHasLink(line)
      })
    },

    _linkRegex() {
      return /(https?:\S*)/gi
    },

    _emailRegex() {
      return /(\S+@\S+\.\S+)/gi
    },

    _lineHasLink(line) {
      return line.match(this._linkRegex()) || line.match(this._emailRegex())
    },

    _renderTechnicalDetailLine(line, index) {

      var innerHtml = line.replace(this._linkRegex(), '<a href=\'\$1\' target=\'_blank\'>\$1</a>').replace(this._emailRegex(), '<a href=\'mailto:\$1\'>\$1</a>')
      return (
        <div key={'technical_detail_' + index} className='row line font-size-m padding-inset-s' dangerouslySetInnerHTML={{__html: innerHtml}}>
        </div>
      )
    },

    _renderTechnicalDetailLines(text) {
      return this._technicalDetailLinesWithLinks(text).map((line, index) => {
        return this._renderTechnicalDetailLine(line, index)
      })
    },

    renderAdditional(f) {

      if(f.type == 'software_information') {

        if(!f.state.text) {
          return null
        }

        return (
          this._renderTechnicalDetailLines(f.state.text)
        )


      }

      else
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

            var onRemoveExisting = (event) => {
              event.preventDefault()

              var l = window.lodash
              var next = l.cloneDeep(f.state.properties)
              next[index].delete = true

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'properties'
                ],
                next
              )

            }

            var onRemove = (event) => {
              event.preventDefault()

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'properties'
                ],
                _.reject(f.state.properties, (pi, i) => i == index)
              )

            }

            var undo = (event) =>  {
              event.preventDefault()

              var l = window.lodash
              var next = l.cloneDeep(f.state.properties)
              next[index].delete = false

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'properties'
                ],
                next
              )
            }


            if(property.type == 'existing') {

              if(property.delete) {

                return (
                  <div key={'property_' + index} className='row line font-size-xs focus-hover-thin striked' data-type='inline-entry'>
                    <div className='line-col' title='Wird beim speichern entfernt'>
                      <i className='fa fa-trash'></i>
                    </div>
                    <div className='line-col col1of10 text-align-left no-padding text-align-center cursor-move ui-sortable-handle' data-type='sort-handle'>
                      <i className='fa fa-resize-vertical'></i>
                    </div>
                    <div className='line-col col4of10 no-padding'>
                      <input onChange={(e) => onChangeKey(e)} value={property.key} disabled className='small width-full' name='model[properties_attributes][][key]' type='text' />
                    </div>
                    <div className='line-col col4of10'>
                      <input onChange={(e) => onChangeValue(e)} value={property.value} disabled className='small width-full' name='model[properties_attributes][][value]' type='text' />
                    </div>
                    <div className='line-col col1of10 text-align-right'>
                      <button onClick={(e) => undo(e)} className='button small inset' data-remove='' title='Entfernen'>{_jed('undo')}</button>
                    </div>
                  </div>
                )


              } else {


                return (
                  <div key={'property_' + index} className='row line font-size-xs focus-hover-thin' data-type='inline-entry'>
                    <div className='line-col col1of10 text-align-left no-padding text-align-center cursor-move ui-sortable-handle' data-type='sort-handle'>
                      <i className='fa fa-resize-vertical'></i>
                    </div>
                    <div className='line-col col4of10 no-padding'>
                      <input onChange={(e) => onChangeKey(e)} value={property.key} className='small width-full' name='model[properties_attributes][][key]' type='text' />
                    </div>
                    <div className='line-col col4of10'>
                      <input onChange={(e) => onChangeValue(e)} value={property.value} className='small width-full' name='model[properties_attributes][][value]' type='text' />
                    </div>
                    <div className='line-col col1of10 text-align-right'>
                      <button onClick={(e) => onRemoveExisting(e)} className='button small inset' data-remove='' title={_jed('Remove')}>{_jed('Remove')}</button>
                    </div>
                  </div>
                )


              }



            }


            else {



              return (
                <div key={'property_' + index} className='row line font-size-xs focus-hover-thin' data-type='inline-entry'>
                  <div className='line-col col1of10 text-align-left no-padding text-align-center cursor-move ui-sortable-handle' data-type='sort-handle'>
                    <i className='fa fa-resize-vertical'></i>
                  </div>
                  <div className='line-col col4of10 no-padding'>
                    <input onChange={(e) => onChangeKey(e)} value={property.key} className='small width-full' name='model[properties_attributes][][key]' type='text' />
                  </div>
                  <div className='line-col col4of10'>
                    <input onChange={(e) => onChangeValue(e)} value={property.value} className='small width-full' name='model[properties_attributes][][value]' type='text' />
                  </div>
                  <div className='line-col col1of10 text-align-right'>
                    <button onClick={(e) => onRemove(e)} className='button small inset' data-remove='' title={_jed('Remove')}>{_jed('Remove')}</button>
                  </div>
                </div>
              )



            }

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

            var onRemoveExisting = (event) => {
              event.preventDefault()

              var l = window.lodash
              var next = l.cloneDeep(f.state.images)
              next[index].delete = true

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'images'
                ],
                next
              )

            }

            var undo = (event) =>  {
              event.preventDefault()

              var l = window.lodash
              var next = l.cloneDeep(f.state.images)
              next[index].delete = false

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'images'
                ],
                next
              )
            }


            if(image.type == 'existing') {


              if(image.delete) {
                return (
                  <div key={'image_' + image.id} className='row line font-size-xs focus-hover-thin striked' data-type='inline-entry'>
                    <div className='line-col col1of10' title='Wird beim speichern entfernt'>
                      <i className='fa fa-trash'></i>
                    </div>
                    <div className='line-col col1of10 text-align-center'>
                      <a href={'/images/' + image.id + '/thumbnail'} target='_blank'>
                        <img className='max-height-xxs max-width-xxs' src={'/images/' + image.id + '/thumbnail'} />
                      </a>
                    </div>
                    <div className='line-col col5of10 text-align-left'>
                      <a className='blue' href={'/images/' + image.id} target='_blank'>
                        {image.filename}
                      </a>
                    </div>
                    <div className='line-col col3of10 text-align-right'>
                      <button onClick={(e) => undo(e)} className='button small inset' data-remove=''>{_jed('undo')}</button>
                    </div>
                  </div>
                )

              } else {

                return (
                  <div key={'image_' + image.id} className='row line font-size-xs focus-hover-thin' data-type='inline-entry'>
                    <div className='line-col col1of10 text-align-center'>
                      <a href={'/images/' + image.id + '/thumbnail'} target='_blank'>
                        <img className='max-height-xxs max-width-xxs' src={'/images/' + image.id + '/thumbnail'} />
                      </a>
                    </div>
                    <div className='line-col col6of10 text-align-left'>
                      <a className='blue' href={'/images/' + image.id} target='_blank'>
                        {image.filename}
                      </a>
                    </div>
                    <div className='line-col col3of10 text-align-right'>
                      <button onClick={(e) => onRemoveExisting(e)} className='button small inset' data-remove=''>Entfernen</button>
                    </div>
                  </div>
                )

              }




            } else {


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


            var onRemoveExisting = (event) => {
              event.preventDefault()

              var l = window.lodash
              var next = l.cloneDeep(f.state.attachments)
              next[index].delete = true

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'attachments'
                ],
                next
              )

            }

            var undo = (event) =>  {
              event.preventDefault()

              var l = window.lodash
              var next = l.cloneDeep(f.state.attachments)
              next[index].delete = false

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'attachments'
                ],
                next
              )
            }

            if(attachment.type == 'existing') {


              if(attachment.delete) {

                return (
                  <div key={'attachment_' + attachment.id} className='row line font-size-xs focus-hover-thin striked' data-type='inline-entry'>
                    <div className='line-col' title='Wird beim speichern entfernt'>
                      <i className='fa fa-trash'></i>
                    </div>
                    <div className='line-col col7of10 text-align-left'>
                      <a className='blue' href={'/attachments/' + attachment.id} target='_blank'>
                        {attachment.filename}
                      </a>
                    </div>
                    <div className='line-col col3of10 text-align-right'>
                      <button onClick={(e) => undo(e)} className='button small inset' data-remove='' type='button'>{_jed('undo')}</button>
                    </div>
                  </div>
                )

              } else {

                return (
                  <div key={'attachment_' + attachment.id} className='row line font-size-xs focus-hover-thin' data-type='inline-entry'>
                    <div className='line-col col7of10 text-align-left'>
                      <a className='blue' href={'/attachments/' + attachment.id} target='_blank'>
                        {attachment.filename}
                      </a>
                    </div>
                    <div className='line-col col3of10 text-align-right'>
                      <button onClick={(e) => onRemoveExisting(e)} className='button small inset' data-remove='' type='button'>{_jed('Remove')}</button>
                    </div>
                  </div>
                )


              }

            } else {


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

            var onRemove = (event) => {
              event.preventDefault()

              var nextAccessories = null
              var l = window.lodash

              if(f.state.accessories[index].id) {
                nextAccessories = l.cloneDeep(f.state.accessories)
                nextAccessories[index].delete = true
              } else {
                nextAccessories = _.reject(f.state.accessories, (ai, i) => i == index)
              }


              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'accessories'
                ],
                nextAccessories
              )
            }

            var onUndo = () => {

              event.preventDefault()

              var l = window.lodash
              var nextAccessories = null
              nextAccessories = l.cloneDeep(f.state.accessories)
              nextAccessories[index].delete = false

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'accessories'
                ],
                nextAccessories
              )
            }



            if(a.delete) {
              return (

                <div key={'accessory_' + index} className='row line font-size-xs focus-hover-thin striked' data-type='inline-entry'>
                  <div className='line-col' title='Wird beim speichern entfernt'>
                    <i className='fa fa-trash'></i>
                  </div>
                  <label className='line-col col1of10 text-align-center no-padding'>
                    <input onChange={(e) => onChange(e)} checked={a.active} autoComplete='off' name='model[accessories_attributes][uid1][inventory_pool_toggle]' type='checkbox' />
                  </label>
                  <div className='line-col col6of10 text-align-left'>
                    {a.label}
                  </div>
                  <div className='line-col col3of10 text-align-right'>
                    <button onClick={(e) => onUndo(e)} className='button small inset' data-remove=''>{_jed('undo')}</button>
                  </div>
                </div>


              )


            } else {
              return (
                <div key={'accessory_' + index} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
                  <label className='line-col col1of10 text-align-center no-padding'>
                    <input onChange={(e) => onChange(e)} checked={a.active} autoComplete='off' name='model[accessories_attributes][uid1][inventory_pool_toggle]' type='checkbox' />
                  </label>
                  <div className='line-col col6of10 text-align-left'>
                    {a.label}
                  </div>
                  <div className='line-col col3of10 text-align-right'>
                    <button onClick={(e) => onRemove(e)} className='button small inset' data-remove=''>{_jed('Remove')}</button>
                  </div>
                </div>
              )
            }





          }

        )

      }

      else if(f.type == 'search-selections') {

        var allocationRed = false
        if(f.key == 'allocations' && this.isEdit()) {
          var sumQuantity = _.reduce(
            f.state.selections,
            (m, s) => {
              if(s.delete) {
                return 0
              } else {
                return m + (isNaN(parseInt(s.quantity)) ? 0 : parseInt(s.quantity))
              }
            },
            0
          )
          allocationRed = sumQuantity > this.props.edit_data.max_borrowable_quantity
        }

        return _.map(
          f.state.selections,
          (s, index) => {



            var onRemove = (event) => {

              event.preventDefault()

              var next = null
              var l = window.lodash

              if(f.state.selections[index].id) {
                next = l.cloneDeep(f.state.selections)
                next[index].delete = true
              } else {
                next = _.reject(f.state.selections, (ai, i) => i == index)
              }

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'selections'
                  // index,
                  // 'quantity'
                ],
                next
              )
            }

            var onUndo = () => {

              event.preventDefault()

              var l = window.lodash
              var next = null
              next = l.cloneDeep(f.state.selections)
              next[index].delete = false

              this.updateState(
                [
                  'fields',
                  _.findIndex(this.state.fields, (fi) => f.key == fi.key),
                  'state',
                  'selections'
                ],
                next
              )
            }

            if(f.key == 'allocations') {

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

              var red = null

              if(allocationRed) {
                red = <div className='line-info red'></div>
              }


              if(s.delete) {

                return (
                  <div key={s.group_id} className='row line font-size-xs focus-hover-thin striked' data-type='inline-entry'>
                    {red}
                    <div className='line-col' title='Wird beim speichern entfernt'>
                      <i className='fa fa-trash'></i>
                    </div>
                    <div className='line-col col3of5 text-align-left' data-name='AV-Services'>
                      <a href={'/manage/' + this.props.inventory_pool_id + '/groups/' + s.group_id + '/edit'}>
                        {s.label}
                      </a>
                    </div>
                    <div className='line-col col1of5 text-align-center'>
                      <input value={s.quantity} onChange={(e) => onChange(e)} disabled autoComplete='off' className='width-xs small text-align-center' name='model[partitions_attributes][uid23][quantity]' type='text' />
                    </div>
                    <div className='line-col col1of5 text-align-right'>
                      <button onClick={(e) => onUndo(e)} className='button small inset' data-remove='' type='button'>{_jed('undo')}</button>
                    </div>
                  </div>
                )

              } else {

                return (
                  <div key={s.group_id} className='row line font-size-xs focus-hover-thin' data-new='' data-type='inline-entry'>
                    {red}
                    <div className='line-col col3of5 text-align-left' data-name='AV-Techniker'>
                      <a href={'/manage/' + this.props.inventory_pool_id + '/groups/' + s.group_id + '/edit'}>
                        {s.label}
                      </a>
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

              }


            } else {

              if(s.delete) {

                return (
                  <div key={s.id} className='row line font-size-xs focus-hover-thin striked' data-type='inline-entry'>
                    <div className='line-col' title='Wird beim speichern entfernt'>
                      <i className='fa fa-trash'></i>
                    </div>
                    <div className='line-col col2of3 text-align-left'>
                      {s.label}
                    </div>
                    <div className='line-col col1of3 text-align-right'>
                      <button onClick={(e) => onUndo(e)} className='button small inset' data-remove='' type='button'>{_jed('undo')}</button>
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


          }
        )
      } else {
        return null
      }

    },


    renderField(f) {

      var renderLabel = () => {
        if(f.key == 'allocations') {
          if(this.isEdit()) {
            return _jed(f.label) + ' (max. ' + this.props.edit_data.max_borrowable_quantity + ')'
          } else {
            return _jed(f.label)
          }
        } else {
          return _jed(f.label)
        }
      }
      var renderMandatory = () => (f.mandatory ? ' *' : null)

      var labelStyle = {
        color: (f.disabled ? '#aaa' : '3a3a3a')
      }

      return (

        <div key={f.key} id={f.key} className='field row emboss margin-vertical-xxs margin-right-xs'>
          <div className='row padding-inset-xs'>
            <div className='col1of2 padding-vertical-xs'>
              <strong className='font-size-m inline-block' style={labelStyle}>
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
