
window.LeftOrRightColumn = {

  _columnGroupFieldModels(fields, fieldModels, leftOrRight) {
    if(leftOrRight == 'left') {
      return this._groupFieldModels(this._columnedGroups(fields).left, fieldModels)
    } else if(leftOrRight == 'right') {
      return this._groupFieldModels(this._columnedGroups(fields).right, fieldModels)
    } else {
      throw 'Unexpected parameter: ' + leftOrRight
    }

  },


  _groupFieldModels(groupedFields, fieldModels) {

    return _.map(
      groupedFields,
      (groupFields) => {
        var group = groupFields.group

        return {
          group: group,
          fieldModels: _.filter(
            fieldModels,
            (fieldModel) => {
              return fieldModel.field.group == group
            }
          )
        }
      }
    )
  },


  _baseFields(fields) {
    return _.filter(fields, (field) => field.group == null)
  },

  _otherFields(fields) {
    return _.filter(fields, (field) => field.group != null)
  },

  _baseGroup(fields) {
    return {
      group: null,
      fields: this._baseFields(fields)
    }
  },

  _otherGroups(fields) {

    return (
      _.map(
        _.groupBy(
          this._otherFields(fields),
          (f) => f.group
        ),
        (groupFields, groupName) => {
          return {
            group: groupName,
            fields: groupFields
          }
        }
      )
    )
  },


  _groupFields(fields) {
    return (
      [ this._baseGroup(fields) ]
      .concat(this._otherGroups(fields))
    )
  },


  _columnedGroups(fields) {

    return this._columnedGroupsRecursive(
      {
        groupsToDivide: this._groupFields(fields),
        left: [],
        right: []
      },
      fields
    )
  },


  _dependents(field, allFields) {
    return allFields.filter((field) => {
      return field.values_dependency_field_id == field.id
    })

  },

  _countFieldsForModel(field, allFields) {
    var dependents = this._dependents(field, allFields)
    if(dependents.length > 0) {
      return 1 + this._countFieldsForModel(dependents[0], allFields)
    } else {
      return 1
    }

  },

  _countFieldsModelFields(fields, allFields) {
    var agg = 0
    for(var i = 0; i < fields.length; i++) {
      agg += this._countFieldsForModel(fields[i], allFields)
    }
    return agg
  },


  _countFieldsForColum(column, allFields) {
    return _.reduce(
      column,
      (agg, val) => {
        return agg + this._countFieldsModelFields(val.fields, allFields)
      },
      0
    )
  },

  _columnedGroupsRecursive(params, allFields) {

    if(params.groupsToDivide.length < 1) {
      return params;

    } else {

      var groupsToDivide = params.groupsToDivide
      var left = params.left
      var right = params.right


      if(this._countFieldsForColum(left, allFields) <= this._countFieldsForColum(right, allFields)) {
        return this._columnedGroupsRecursive({
          groupsToDivide: _.rest(groupsToDivide),
          left: left.concat(_.first(groupsToDivide)),
          right: right
        }, allFields)
      } else {
        return this._columnedGroupsRecursive({
          groupsToDivide: _.rest(groupsToDivide),
          left: left,
          right: right.concat(_.first(groupsToDivide))
        }, allFields)
      }


    }
  }

}
