window.FieldModels = {

  _getTodayAsString() {
    return moment().format(i18n.date.L)
  },

  _createEmptyValue(field, next_code, inventory_pool) {
    if(field.id == 'inventory_code') {
      return {text: next_code}
    } else if(field.id == 'owner_id') {
      return {
        text: inventory_pool.name,
        id: inventory_pool.id
      }
    } else if(field.id == 'last_check') {

      return {
        at: this._getTodayAsString()
      }
    } else {
      return window.CreateItemFieldSwitch._createEmptyValue(field)
    }
  },


  _itemValue(field, item) {

    var itemValue = null

    if (field.form_name) {
      itemValue = item[field.form_name]
    } else {
      itemValue = window.CreateItemFieldSwitch._itemValue(field.attribute, item)
    }

    return itemValue
  },

  _ensureDependents(fieldModels, fields, _fieldSwitch) {
    EnsureDependents._ensureDependents(fieldModels, fields, _fieldSwitch())
  },


  _createEditFieldModelRec(fields, field, item, _fieldSwitch, attachments) {

    var value = null

    if(field.type == 'attachment') {
      value = window.CreateItemFieldSwitch._createEditValue(field, item, null, attachments)
    } else {
      var itemValue = this._itemValue(field, item)
      if(itemValue != null && itemValue != undefined) {
        value = window.CreateItemFieldSwitch._createEditValue(field, item, itemValue, null)
      } else {
        value = window.CreateItemFieldSwitch._createEmptyValue(field)
      }
    }

    var selectedValue = {
      field: field,
      value: value,
      dependents: [],
      hidden: (field.hidden ? true : false)

    }

    var dependents = window.EnsureDependents._determineDependents(fields, selectedValue, _fieldSwitch())


    selectedValue.dependents = dependents.map((d) => {
      return this._createEditFieldModelRec(fields, d, item, _fieldSwitch, attachments)
    })

    return selectedValue

  },

  _onlyMainFields(fields) {

    return fields.filter((f) => {
      return !f['visibility_dependency_field_id'] && !f['values_dependency_field_id']
    })
  },


  _createEditFieldModels(fields, item, _fieldSwitch, attachments) {

    return _.compact(
      this._onlyMainFields(fields).map((field) => {
        return window.FieldModels._createEditFieldModelRec(fields, field, item, _fieldSwitch, attachments)
      })
    )
  },


  _createNewFieldModels(fields, next_code, inventory_pool, _fieldSwitch) {

    var fms = this._onlyMainFields(fields).map((field) => {
        return {
            field: field,
            value: window.FieldModels._createEmptyValue(field, next_code, inventory_pool),
            dependents: [],
            hidden: (field.hidden ? true : false)
          }
      })

    this._ensureDependents(fms, fields, _fieldSwitch)

    return fms
  },



  findFieldModelRec(fieldModel, fieldId) {

    if(fieldModel.field.id == fieldId) {
      return fieldModel
    } else {
      return this.findFieldModel(fieldModel.dependents, fieldId)
    }
  },

  findFieldModel(fieldModels, fieldId) {
    for(var i = 0; i < fieldModels.length; i++) {
      var d = fieldModels[i]
      var fm = this.findFieldModelRec(d, fieldId)
      if(fm) {
        return fm
      }
    }
    return null
  },





  _recursiveFieldModels(fieldModel) {

    if(fieldModel.dependents && fieldModel.dependents.length > 0) {

      return _.reduce(
        fieldModel.dependents,
        (result, dependent) => {
          return result.concat(
            this._recursiveFieldModels(dependent, result)
          )
        },
        [fieldModel]
      )
    } else {
      return [fieldModel]
    }

  },

  _flatFieldModels(fieldModels) {
    var r = _.reduce(
      fieldModels,
      (result, fieldModel) => {
        return result.concat(
          this._recursiveFieldModels(fieldModel)
        )
      },
      []
    )
    return r
  }

}
