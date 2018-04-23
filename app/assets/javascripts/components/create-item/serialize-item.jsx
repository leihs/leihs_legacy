window.SerializeItem = {

  _serializeFieldValue(fieldModel) {

    var field = fieldModel.field
    var value = fieldModel.value

    if(field.id == 'properties_quantity_allocations') {
      return _.filter(value.allocations, (a) => !a.deleted).map((v) => {
        return {
          quantity: v.quantity,
          room: v.location
        }
      })
    }

    switch(field.type) {
      case 'text':
        return value.text
        break
      case 'autocomplete-search':
        return value.id
        break
      case 'autocomplete':
        return value.id
        break
      case 'textarea':
        return value.text
        break
      case 'select':
        return value.selection
        break
      case 'radio':
        return value.selection
        break
      case 'checkbox':
        return value.selections
        break
      case 'date':
        var dmy = CreateItemFieldSwitch._parseDayMonthYear(value.at)
        return CreateItemFieldSwitch._dmyToString(dmy)
        break
      // case 'attachment':
      //   throw
      //   return ''
      //   break
      default:
        throw 'Unexpected type: ' + field.type
    }
  },



  _serializeExtensibleFieldValue(fieldModel) {

    var field = fieldModel.field
    var value = fieldModel.value

    if(field.type == 'autocomplete') {
      return value.text
    } else {
      throw 'Not supported field type: ' + field.type
    }
  },



  _serializeItem(bypassSerialNumberValidation, fieldModels) {

    var base = {};
    if(bypassSerialNumberValidation) {
      base.skip_serial_number_validation = 'true'
    } else {
      base.skip_serial_number_validation = 'false'
    }

    return _.reduce(
      fieldModels,
      (result, fieldModel) => {

        var field = fieldModel.field

        var value = window.SerializeItem._serializeFieldValue(fieldModel)
        if (field.form_name) {
          result[field.form_name] = value
        } else if (field.attribute instanceof Array) {
          BackwardTestCompatibility._setValue(result, field.attribute, value)
        } else {
          result[field.attribute] = value
        }

        if(field.extensible) {
          var extensibleValue = window.SerializeItem._serializeExtensibleFieldValue(fieldModel)
          BackwardTestCompatibility._setValue(result, field.extended_key, extensibleValue)
        }

        return result
      },
      base
    )
  },


}
