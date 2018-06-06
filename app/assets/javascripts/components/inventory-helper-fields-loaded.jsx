(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this


  window.InventoryHelperFieldsLoaded = window.createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        selectedValues: [],
        currentItem: {
          byId: null,
          byInventoryCode: null,
          loadResult: null
        },
        editFieldModels: null,
        editMode: false,
        saving: false,
        savingResult: null,
        autocompleteItemId: null
      }
    },

    ownerSelected(selectedValues) {
      return _.find(
        selectedValues,
        (sv) => {
          return sv.field.id == 'owner_id' && sv.value.id != null
        }
      )
    },

    showOnwerHint() {
      App.Flash({
        type: 'notice',
        message: _jed('If you transfer an item to a different inventory pool it\'s not visible for you anymore.'),
      })
    },



    selectedValuesChanged(selectedValues) {
      var selectedFlat = window.FieldModels._flatFieldModels(selectedValues)

      if(this.ownerSelected(selectedValues)) {
        this.showOnwerHint()
      }

      this.setState(
        {
          selectedValues: selectedValues
        }
      )
    },


    fieldsForForm() {
      return _.filter(this.props.fields, (f) => f.type != 'attachment')
    },



    onNextEditFieldModels(nextEditFieldModels) {
      this.setState({editFieldModels: nextEditFieldModels})
    },




    renderForm() {

      if(this.state.saving) {
        return window.InventoryHelperRenderer.renderLoadingItem()
      }
      else if(!this.state.currentItem.loadResult) {
        return window.InventoryHelperRenderer.renderNoItemSelected()
      }
      else {
        if(this.state.editMode) {
          return window.InventoryHelperRenderer.renderItemEditor(
            this.state.currentItem.loadResult,
            this.fieldsForForm(),
            this.state.editFieldModels,
            this.onNextEditFieldModels
          )
        } else {
          return window.InventoryHelperRenderer.renderAssignResult(
            this.fieldsForForm(),
            this.state.currentItem.loadResult,
            this.state.selectedValuesForSave,
            this.state.savingResult
          )
        }
      }
    },






    _editItemFieldSwitch() {
      return {
        _hasValidValue: CreateItemFieldSwitch._hasValidValue,
        _createEmptyValue: CreateItemFieldSwitch._createEmptyValue,
        _isDependencyValue: CreateItemFieldSwitch._isDependencyValue
      }
    },


    createFieldModels(fields, item) {
      return window.FieldModels._createEditFieldModels(fields, item, this._editItemFieldSwitch, [])
    },

    updateEditItem() {

      var mergedFieldModels = _.filter(
        window.FieldModels._flatFieldModels(this.state.editFieldModels),
        (fm) => {
          return fm.field.type != 'attachment' && !fm.field.exclude_from_submit && CreateItemFieldSwitch._isFieldEditable(fm.field, this.state.currentItem.loadResult)
        }
      )

      this.ajaxUpdateItem(
        mergedFieldModels,
        (response) => {

          this.setState((old) => {
            var l = window.lodash
            var next = l.cloneDeep(old)
            next.currentItem.loadResult = response
            next.saving = false
            next.savingResult = null
            next.editMode = false
            return next
          }, () => {

          })

        }
      )

    },

    ajaxUpdateItem(mergedFieldModels, callback) {

      var serialized = window.SerializeItem._serializeItem(true, mergedFieldModels)

      var data = {
        inventory_pool_id: this.props.inventory_pool_id,
        item: serialized
      }

      var url = '/manage/' + this.props.inventory_pool_id + '/items/' + this.state.currentItem.loadResult.id


      window.leihsAjax.putAjax(
        url,
        data,
        (status, data) => {

          if(status == 'success') {

            var l = window.lodash

            this.showFlashSuccess('Item was saved.')

            window.leihsAjax.getAjax(
              '/manage/' + this.props.inventory_pool_id + '/items/' + this.state.currentItem.loadResult.id + '?for=flexibleFields',
              {},
              (status, response) => {

                callback(response)
              }
            )

          } else {


            if(data.responseJSON && data.responseJSON.message) {
              this.showFlashError(_jed('Item was not saved') + ' - ' + _jed(data.responseJSON.message))
            } else {
              this.showFlashError(_jed('Item was not saved') + ' - ' + _jed('Unexpected error.'))
            }

            this.setState({
              saving: false,
              savingResult: 'error'
            }, () => {

            })
          }


        }
      )

    },

    updateItem() {

      var mergedFieldModels = _.filter(
        window.FieldModels._flatFieldModels(this.state.selectedValues),
        (fm) => {
          return fm.field.type != 'attachment' && !fm.field.exclude_from_submit /*&& CreateItemFieldSwitch._isFieldEditable(fm.field, this.state.currentItem.loadResult)*/
        }
      )

      // if(mergedFieldModels.length == 0) {
      //   this.showFlashError(_jed('You dont have the permission to update any of the selected fields.'))
      //   this.setState({
      //     saving: false
      //   })
      //   return
      // }

      this.ajaxUpdateItem(
        mergedFieldModels,
        (response) => {

          this.setState((old) => {
            var l = window.lodash
            var next = l.cloneDeep(old)
            next.currentItem.loadResult = response
            next.saving = false
            next.savingResult = 'success'
            return next
          }, () => {

          })

        }
      )



    },

    applySelectedFieldsToItem(itemId) {
      var l = window.lodash

      window.leihsAjax.getAjax(
        '/manage/' + this.props.inventory_pool_id + '/items/' + itemId + '?for=flexibleFields',
        {},
        (status, response) => {
          this.setState((old) => {
            var next = l.cloneDeep(old)
            next.currentItem.loadResult = response
            return next
          }, () => {
            this.updateItem()
          })
        }
      )

    },

    cancelApplyByBarcode() {
      this.setState((old) => {
        var l = window.lodash
        var next = l.cloneDeep(old)
        next.saving = false
        next.currentItem.byInventoryCode = null
        return next
      })
    },

    prepareApplyByBarcode() {

      var l = window.lodash

      window.leihsAjax.getAjax(
        '/manage/' + this.props.inventory_pool_id + '/items?inventory_code=' + this.state.currentItem.byInventoryCode,
        {},
        (status, result) => {
          if(result.length != 1) {
            App.Flash({
              type: 'error',
              message: _jed('The Inventory Code %s was not found.', this.state.currentItem.byInventoryCode)
            })

            this.cancelApplyByBarcode()

          } else {
            this.applySelectedFieldsToItem(result[0].id)
          }
        }
      )

    },

    onChangeItemId(id, term) {
      this.setState({
        autocompleteItemId: id,
        autocompleteItemTerm: term
      })
    },

    cancelSelection() {
      this.setState({
        autocompleteItemId: null,
        autocompleteItemTerm: null
      })
    },


    startApplyBySearch(callback) {

      this.setState((old) => {
        var l = window.lodash
        var next = l.cloneDeep(old)
        next.selectedValuesForSave = l.cloneDeep(this.state.selectedValues)
        next.currentItem.byId = old.autocompleteItemId
        next.currentItem.loadResult = null
        next.saving = true
        next.editMode = false
        return next
      }, () => {

        this.applySelectedFieldsToItem(this.state.currentItem.byId)

      })

    },

    onApplyBySearch(event) {

      var l = window.lodash

      this.hideFlash()

      if(!this.state.autocompleteItemId) {
        this.showFlashError(_jed('Please select an item.'))
        return
      }

      if(this.state.selectedValues.length == 0) {
        this.showFlashError(_jed('Please select some fields.'))
        return
      }

      this.startApplyBySearch()

    },



    hideFlash() {
      App.Flash.reset()
    },

    showFlashError(message) {
      App.Flash({
        type: 'error',
        message: message
      })
    },

    showFlashSuccess(message) {
      App.Flash({
        type: 'success',
        message: _jed(message)
      })
    },

    showInvalidFlash() {
      App.Flash({
        type: 'error',
        message: _jed('Please provide all required fields')
      })
    },


    renderSaveButton() {

      var onSave = (event) => {

        if(!window.CreateItemValidation._clientValidation(
          this.state.editFieldModels
        )) {

          this.showInvalidFlash()
        } else {
          this.hideFlash()
        }

        this.setState({
          saving: true
        }
        ,
        () => {
          this.updateEditItem()
        })

      }

      return (
        <button onClick={(e) => onSave(e)} className={'button green' + (!this.state.editMode ? ' hidden' : '')} id='save-edit'>{_jed('Save changes')}</button>

      )

    },

    renderCancelButton() {

      var onCancel = (event) => {
        this.setState({
          editMode: false
        })
      }

      return (
        <a onClick={(e) => onCancel(e)} className={'button' + (!this.state.editMode ? ' hidden' : '')} id='cancel-edit'>{_jed('Cancel')}</a>
      )
    },

    renderEditButton() {

      var onEdit = (event) => {
        this.setState({
          editMode: true,
          editFieldModels:  this.createFieldModels(this.fieldsForForm(), this.state.currentItem.loadResult)
        })
      }

      return (
        <button onClick={(e) => onEdit(e)} className={'button white' + (this.state.editMode ? ' hidden' : '')} id='item-edit'>{_jed('Edit Item')}</button>
      )
    },

    renderButtons() {


      if(this.state.saving) {
        return
      }
      if(!this.state.currentItem.loadResult) {
        return
      }

      return (
        <div className='col1of3 text-align-right'>
          {this.renderEditButton()}
          {this.renderCancelButton()}
          {this.renderSaveButton()}
        </div>

      )

    },



    startApplyByBarcode(inventoryCode, callback) {

      this.setState(
        (old) => {
          var l = window.lodash
          var next = l.cloneDeep(old)
          next.selectedValuesForSave = l.cloneDeep(this.state.selectedValues)
          next.currentItem.byInventoryCode = inventoryCode
          next.currentItem.loadResult = null
          next.saving = true
          next.editMode = false
          return next
        },
        () => {
           this.prepareApplyByBarcode()
        }
      )


    },


    checkApplyByBarcode(inventoryCode) {
      if(inventoryCode.length == 0) {
        this.showFlashError(_jed('Please provide an inventory code'))
        return
      }

      if(this.state.selectedValues.length == 0) {
        this.showFlashError(_jed('Please select some fields.'))
        return
      }

      this.startApplyByBarcode(inventoryCode)

    },

    onApplyByBarcode(event) {
      event.preventDefault()

      var inventoryCode = this.barcodeInput.value
      this.barcodeInput.value = ''

      this.hideFlash()

      this.checkApplyByBarcode(inventoryCode)
    },

    renderNotOwner() {
      return null

      // if(!this.state.currentItem.loadResult) {
      //   return
      // }
      //
      //
      // var isOwner = () => {
      //
      //   var ownerId = this.state.currentItem.loadResult.owner_id
      //   return ownerId == this.props.inventory_pool_id
      //
      // }
      //
      // if(isOwner()) {
      //   return null
      // }
      //
      //
      // return (
      //   <div className='row emboss red text-align-center font-size-m padding-inset-s'>
      //     <strong>Sie sind nicht Besitzer dieses Gegenstands, deshalb können Sie einige Felder nicht editieren</strong>
      //   </div>
      // )

    },

    setBarcodeRef(ref) {
      this.barcodeInput = ref

    },

    renderManualInput() {
      if(this.state.autocompleteItemId) {
        return (
          <div className='row' style={{height: '50px', marginLeft: '5px', border: '1px dashed #bbb', borderRadius: '5px', padding: '5px', marginTop: '10px', marginBottom: '10px', textAlign: 'center'}}>
            <div style={{width: '100%', display: 'inline-block'}}>
              <div className='row' style={{fontSize: '16px', color: 'rgb(153, 153, 153)', display: 'inline-block', clear: 'none', width: '50%', marginRight: '10px'}}>
                {this.state.autocompleteItemTerm}
                <i className='fa fa-times-circle' style={{margin: '0px 10px'}} onClick={(e) => this.cancelSelection()}></i>
              </div>
              <button onClick={(e) => this.onApplyBySearch(e)} className='button green' type='submit' >{_jed('and assign fields')}</button>
            </div>
          </div>

        )
      } else {
        return window.InventoryHelperRenderer.renderManualInput(this.props.inventory_pool_id, this.onChangeItemId, this.onApplyBySearch)
      }
    },

    renderItem() {

      return (
        <div className='row padding-inset-m' id='item-section'>
          <div className='row' style={{marginBottom: '30px'}}>
            <div className='col1of2'>
              {window.InventoryHelperRenderer.renderBarcodeInput(this.setBarcodeRef, this.onApplyByBarcode)}
            </div>
            <div className='col1of2'>
              {this.renderManualInput()}
            </div>
          </div>
          <div className='row'>
            <div className='col2of3' />
            {this.renderButtons()}
          </div>
          <div className='padding-vertical-m' id='notifications'>
            {this.renderNotOwner()}
          </div>
          {this.renderForm()}
        </div>
      )
    },


    render () {
      return (
        <div className='row content-wrapper min-height-xl min-width-full straight-top'>
          <div className='margin-top-l padding-horizontal-m'>
            <div className='row'>
              <h1 className='headline-xl'>{_jed('Inventory Helper')}</h1>
              <h2 className='headline-m light'>{_jed('Process multiple fields for multiple items in a row')}</h2>
            </div>
          </div>
          {window.InventoryHelperRenderer.renderSearchMask(
            this.props.fields,
            this.state.selectedValues,
            this.selectedValuesChanged
          )}
          {this.renderItem()}
        </div>
      )

    }
  })
})()
