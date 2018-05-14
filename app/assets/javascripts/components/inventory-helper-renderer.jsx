window.InventoryHelperRenderer = {


  renderSearchMask(fields, selectedValues, selectedValuesChanged) {


    var _fieldSwitch = () => {
      return {
        _hasValue: (selectedValue) => {
          return FieldSwitch._hasValue(selectedValue, false)
        },
        _createEmptyValue: (field) => {
          return FieldSwitch._createEmptyValue(field, false)
        },
        _isDependencyValue: (selectedValue, fieldDependencyValue) => {
          return FieldSwitch._isDependencyValue(selectedValue, fieldDependencyValue, false)
        },
        _inputByType: (selectedValue, onChangeSelectedValue, dependencyValue) => {
          return FieldSwitch._inputByType(selectedValue, onChangeSelectedValue, dependencyValue, false)
        }
      }
    }

    return (
      <SearchMaskState fields={fields}
        selectedValues={selectedValues}
        selectedValuesChanged={selectedValuesChanged}
        fieldSwitch={_fieldSwitch()}
        divId={'search-mask'}
      />
    )

  },

  renderLoadingItem() {
    return (
      <div className='row' id='flexible-fields'>
        <div className='height-s'></div>
        <div className='loading-bg'></div>
        <div className='height-s'></div>
      </div>
    )
  },


  renderNoItemSelected() {

    return (
      <form className='row' id='flexible-fields'>
        <div className='height-s'></div>
        <h3 className='headline-s light padding-inset-m text-align-center'>{_jed('no item selected')}</h3>
        <div className='height-s'></div>
      </form>
    )

  },


  renderItemEditor(loadResult, fields, editFieldModels, onNextEditFieldModels) {
    var fieldRenderer = (fieldModel, fieldModels, onChange, showInvalids, onClose, dependencyValue, dataDependency) => {

      return CreateItemFieldSwitch.renderField(
        fieldModel,
        dependencyValue,
        dataDependency,
        (value) => onChange(fieldModel.field.id, value),
        loadResult,
        {},
        showInvalids,
        onClose,
        false
      )
    }

    var onClose = () => {}

    var onChangeEditItem = (fieldId, value) => {
      var l = window.lodash
      var nextEditFieldModels = l.cloneDeep(editFieldModels)
      window.FieldModels.findFieldModel(nextEditFieldModels, fieldId).value = value
      window.FieldModels._ensureDependents(nextEditFieldModels, fields, this._editItemFieldSwitch)
      onNextEditFieldModels(nextEditFieldModels)
    }


    return (
      RenderCreateItem._renderColumns(fields, editFieldModels,
        onChangeEditItem, true, onClose, fieldRenderer)
    )
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


  renderAssignResult(fields, loadResult, selectedValuesForSave, savingResult) {

    var fieldModels = this.createFieldModels(fields, loadResult)
    var selectedFlat = window.FieldModels._flatFieldModels(selectedValuesForSave)

    var item = loadResult
    var fieldRenderer = (fieldModel, fieldModels, onChange, showInvalids, onClose, dependencyValue, dataDependency) => {

      var l = window.lodash

      var selected = _.find(selectedFlat, (sf) => sf.field.id == fieldModel.field.id)
      var clazz = null
      if(savingResult != null && selected) {

        if(CreateItemFieldSwitch._isFieldEditable(selected.field, loadResult)) {
          clazz = 'success'
        } else {
          clazz = 'error'
        }


        // if(savingResult == 'success') {
        // } else if(savingResult == 'error') {
        //   clazz = 'error'
        // }
        //
      }

      var v = fieldModel

      return CreateItemFieldSwitch._renderOutputField(
        v,
        dependencyValue,
        dataDependency,
        (value) => onChange(fieldModel.field.id, value),
        showInvalids,
        onClose,
        {
          additionalRowClass: clazz,
          showClose: false
        }
      )
    }

    var onClose = () => {}

    var onChangeEditItem = () => {}

    return (
      RenderCreateItem._renderColumns(fields, fieldModels,
        onChangeEditItem, true, onClose, fieldRenderer)
    )



  },

  renderBarcodeInput(setBarcodeRef, onSubmit) {
    return (
      <div style={{height: '50px', marginRight: '5px', border: '1px dashed #bbb', borderRadius: '5px', padding: '5px', marginTop: '10px', marginBottom: '10px'}}>
        <form className='row' id='item-selection' onSubmit={(e) => onSubmit(e)}>
          <input ref={(ref) => setBarcodeRef(ref)} autoComplete='off' style={{border: 'none', fontSize: '16px', color: '#999', textAlign: 'center', boxShadow: 'none', textAlign: 'center'}} className='width-full ui-autocomplete-input' data-barcode-scanner-target='' id='item-input' placeholder={_jed('use barcode scanner to assign fields to item immediately')} type='text' />
          <button type='submit' style={{position: 'absolute', right: '0px', top: '5px', opacity: '0'}} data-barcode-scanner-submit-button=''>></button>
        </form>
      </div>
    )
  },


  renderManualInput(inventory_pool_id, onChangeItemId, assignFields) {
    return (
      <div className='row' style={{height: '50px', marginLeft: '5px', border: '1px dashed #bbb', borderRadius: '5px', padding: '5px', marginTop: '10px', marginBottom: '10px', textAlign: 'center'}}>
        <div style={{width: '100%', display: 'inline-block'}}>
          {window.InventoryHelperRenderer.renderItemSearch(inventory_pool_id, onChangeItemId)}
          <button onClick={(e) => assignFields(e)} className='button green' type='submit' >{_jed('and assign fields')}</button>
        </div>
      </div>
    )
  },


  renderItemSearch(inventory_pool_id, onChangeItemId) {

    var makeCall = (term, callback) => {

      window.leihsAjax.getAjax(
        '/manage/' + inventory_pool_id + '/items?search_term=' + term,
        {},
        (status, response) => {

          callback(
            _.map(
              response,
              (r) => {
                return {
                  id: r.id,
                  label: r.inventory_code,
                  currentLocation: r.current_location,
                  inventoryCode: r.inventory_code
                }
              }
            )
          )
        }
      )
    }

    var liARenderer = (row) => {
      return (
        <a className='ui-menu-item-wrapper'>
          <div className='row text-ellipsis'>
            <div className='col1of3'>
              <strong>{row.inventoryCode}</strong>
            </div>
            <div className='col2of3 text-ellipsis' title={row.currentLocation}>
              {row.currentLocation}
            </div>
          </div>
        </a>
      )
    }

    var onChange = (result) => {
      var term = result.term
      var id = result.id
      if(id) {
        onChangeItemId(id)
      }
    }


    return (
      <BasicAutocomplete
        inputClassName='has-addon width-full ui-autocomplete-input'
        element='div'
        inputId='item-search-input'
        dropdownWidth='312px'
        label={_jed('or search for item')}
        _makeCall={makeCall}
        onChange={onChange}
        wrapperStyle={{display: 'inline-block', clear: 'none', width: '50%', marginRight: '10px'}}
        liARenderer={liARenderer}
      />
    )
  }







}
