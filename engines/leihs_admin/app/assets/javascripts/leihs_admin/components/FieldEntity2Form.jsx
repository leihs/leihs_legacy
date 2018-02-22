(() => {

  window.FieldEntity2Form = {



    createFieldInput() {
      return {
        id: '',
        label: '',
        packages: false,
        group: '',
        active: false,
        type: 'text',
        target: 'both',
        role: 'lending_manager',
        owner: false,
        newGroupSelected: false,
        groupInput: ''
      }
    },


    readTargetType(targetType) {
      if(!targetType) {
        return 'both'
      } else {
        return targetType
      }

    },


    readValues(field) {

      return field.data.values.map((v) => {
        return {
          label: v.label,
          value: (v.value ? v.value : ''),
          existing: true
        }
      })

    },


    editFieldInput(field) {

      if(!field.dynamic) {
        return {
          id: field.id,
          label: field.data.label,
          active: field.active
        }

      }


      var input = {
        id: field.id,
        label: field.data.label,
        packages: (field.data.forPackage ? true : false),
        group: (field.data.group == null ? '' : field.data.group),
        active: field.active,
        type: field.data.type,
        target: this.readTargetType(field.data.target_type),
        role: field.data.permissions.role,
        owner: field.data.permissions.owner,
        newGroupSelected: false,
        groupInput: ''
      }

      if(field.data.type == 'radio' || field.data.type == 'select' || field.data.type == 'checkbox') {

        if(field.data.values && (field.data.values instanceof Array)) {

          input.values = this.readValues(field)
          if(field.data.type != 'checkbox') {
            var defaultIndex = _.findIndex(field.data.values, (v) => v.value == field.data['default'])
            input.defaultValue = defaultIndex
          }


        }
      }

      return input
    },

  }


})()
