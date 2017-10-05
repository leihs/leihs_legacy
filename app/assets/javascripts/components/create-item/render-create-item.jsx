
window.RenderCreateItem = {


  _renderFieldContent(fieldModel, fieldModels, createItemProps, onChange, showInvalids) {

    var dependencyValue = _.first(_.filter(fieldModels, (other) => {
      return other.field.id == fieldModel.field.values_dependency_field_id
    }))



    return (
      CreateItemFieldSwitch.renderField(
        fieldModel,
        dependencyValue,
        onChange,
        createItemProps,
        showInvalids
      )
    )

  },


  _renderDependents(fieldModel, fieldModels, createItemProps, onChange, showInvalids) {

    if(!fieldModel.dependents) {
      return []
    }

    return fieldModel.dependents.map((dependent) => {
      return this._renderField(dependent, fieldModels, createItemProps, onChange, showInvalids)

    })

  },

  _renderField(fieldModel, fieldModels, createItemProps, onChange, showInvalids) {
    return (
      <div id={fieldModel.field.id} key={fieldModel.field.id}>

        {this._renderFieldContent(
          fieldModel,
          fieldModels,
          createItemProps,
          onChange,
          showInvalids)}

        {this._renderDependents(fieldModel, fieldModels, createItemProps, onChange, showInvalids)}

      </div>
    )
  },

  _renderFieldsInGroup(groupedFieldModels, fieldModels, createItemProps, onChange, showInvalids) {
    return groupedFieldModels.map((fieldModel) => {
      return this._renderField(
        fieldModel,
        fieldModels,
        createItemProps,
        onChange,
        showInvalids)
    })

  },

  _renderGroupNameIfNeeded(groupName) {
    if(groupName) {
      return (
        <h2 className='headline-m padding-bottom-m'>
          {_jed(groupName)}
        </h2>
      )
    } else {
      return null
    }

  },

  _renderFieldsGroup(groupFields, fieldModels, createItemProps, onChange, showInvalids) {

    return (

      <section className='padding-bottom-l' key={groupFields.group}>

        {this._renderGroupNameIfNeeded(groupFields.group)}

        <div className='row group-of-fields'>

          {this._renderFieldsInGroup(
            groupFields.fieldModels,
            fieldModels,
            createItemProps,
            onChange,
            showInvalids)}

        </div>

      </section>
    )
  },



  _renderFieldsGrouped(fields, fieldModels, leftOrRight, createItemProps, onChange, showInvalids) {

    return _.map(
      LeftOrRightColumn._columnGroupFieldModels(fields, fieldModels, leftOrRight),
      (groupFields) => {
        return RenderCreateItem._renderFieldsGroup(groupFields,
          fieldModels,
          createItemProps,
          onChange,
          showInvalids)
      }
    )
  },



  _renderLeftColumn(fields, fieldModels, createItemProps, onChange, showInvalids) {

    return (
      <div className='col1of2 padding-right-xs' id='item-form-left-side'>
        {this._renderFieldsGrouped(fields, fieldModels, 'left', createItemProps, onChange, showInvalids)}
      </div>
    )
  },

  _renderRightColumn(fields, fieldModels, createItemProps, onChange, showInvalids) {
    return (
      <div className='col1of2' id='item-form-right-side'>
        {this._renderFieldsGrouped(fields, fieldModels, 'right', createItemProps, onChange, showInvalids)}
      </div>
    )
  },


  _renderColumns(fields, fieldModels, createItemProps, onChange, showInvalids) {
    return (
      <div id='flexible-fields'>
        {this._renderLeftColumn(fields, fieldModels, createItemProps, onChange, showInvalids)}
        {this._renderRightColumn(fields, fieldModels, createItemProps, onChange, showInvalids)}
      </div>
    )
  }


}
