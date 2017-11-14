
window.BackwardTestCompatibility = {

  // Should be replaced by lodash.
  _setValue(obj, path, val) {
    var fields = path
    var result = obj
    for (var i = 0, n = fields.length; i < n && result !== undefined; i++) {
      var field = fields[i]
      if (i === n - 1) {
        result[field] = val
      } else {
        if (typeof result[field] === 'undefined' || !_.isObject(result[field])) {
          result[field] = {}
        }
        result = result[field]
      }
    }
  },


  _getFormName(selectedValue) {

    var field = selectedValue.field
    if (field.form_name) {
      return '[' + field.form_name + ']'
    } else if (field.attribute instanceof Array) {
      return _.reduce(
        field.attribute,
        (result, part) => {
          return result + '[' + part + ']'
        },
        ''
      )
      this._setValue(result, field.attribute, value)
    } else {
      return '[' + field.attribute + ']'
    }
  },

}
