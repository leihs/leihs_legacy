(() => {

  window.FieldForm2Entity = {

    isInputMulti(fieldInput) {

      var isMulti = false
      if(fieldInput.type == 'radio' || fieldInput.type == 'select' || fieldInput.type == 'checkbox') {

        if(fieldInput.values && (fieldInput.values instanceof Array)) {
          isMulti = true
        }
      }

      return isMulti
    },

    writeValues(values) {

      return values.map((v) => {
        return {
          label: v.label,
          value: (v.value ? v.value : null)
        }
      })


    },

    writeTargetType(target) {
      if(target == 'both') {
        return undefined
      } else {
        return target
      }
    },

    readGroupFromInput(fieldInput) {

      if(fieldInput.newGroupSelected) {

        if(fieldInput.groupInput.trim().length > 0) {
          return fieldInput.groupInput
        } else {
          return null
        }
      } else {
        return (fieldInput.group == '' ? null : fieldInput.group)
      }


    },


    readForEditDynamicAndNew(field, fieldInput) {
      field.active = fieldInput.active
      field.data.label = fieldInput.label
      field.data.group = this.readGroupFromInput(fieldInput)
      field.data.type = fieldInput.type
      field.data.forPackage = fieldInput.packages
      field.data.target_type = this.writeTargetType(fieldInput.target)
      field.data.permissions = {
        role: fieldInput.role,
        owner: fieldInput.owner
      }

      if(this.isInputMulti(fieldInput)) {
        field.data.values = this.writeValues(fieldInput.values)
        if(fieldInput.type != 'checkbox') {
          field.data.default = field.data.values[fieldInput.defaultValue].value
        }
      }

    },

    readEditDynamic(originalField, fieldInput) {

      var field = JSON.parse(JSON.stringify(originalField))

      this.readForEditDynamicAndNew(field, fieldInput)


      return field
    },

    readEditStatic(originalField, fieldInput) {

      var field = JSON.parse(JSON.stringify(originalField))
      field.active = fieldInput.active
      field.data.label = fieldInput.label
      return field

    },

    readNew(fieldInput) {

      var field = {
        id: 'properties_' + fieldInput.id,
        position: 0,
        data: {
          attribute: ['properties', fieldInput.id]
        }
      }

      this.readForEditDynamicAndNew(field, fieldInput)

      return field
    }



  }


})()
