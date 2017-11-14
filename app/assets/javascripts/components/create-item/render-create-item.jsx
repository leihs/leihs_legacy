
window.RenderCreateItem = {


  _renderFieldContent(fieldModel, fieldModels, createItemProps, onChange, showInvalids, onClose) {

    var dependencyValue = _.first(_.filter(fieldModels, (other) => {
      return other.field.id == fieldModel.field.values_dependency_field_id
    }))

    var dataDependency = _.first(_.filter(fieldModels, (other) => {
      return other.field.id == fieldModel.field.data_dependency_field_id
    }))

    return (
      CreateItemFieldSwitch.renderField(
        fieldModel,
        dependencyValue,
        dataDependency,
        onChange,
        createItemProps,
        showInvalids,
        onClose
      )
    )

  },


  _renderDependents(fieldModel, fieldModels, createItemProps, onChange, showInvalids) {

    if(!fieldModel.dependents) {
      return []
    }

    if(fieldModel.hidden) {
      return []
    }

    return fieldModel.dependents.map((dependent) => {
      return this._renderField(dependent, fieldModels, createItemProps, onChange, showInvalids)

    })

  },

  _renderField(fieldModel, fieldModels, createItemProps, onChange, showInvalids, onClose) {

    var _onClose = () => {
      onClose(fieldModel)
    }

    return (
      <div id={fieldModel.field.id} key={fieldModel.field.id}>

        {this._renderFieldContent(
          fieldModel,
          fieldModels,
          createItemProps,
          onChange,
          showInvalids,
          _onClose)}

        {this._renderDependents(fieldModel, fieldModels, createItemProps, onChange, showInvalids)}

      </div>
    )
  },

  _renderFieldsInGroup(groupedFieldModels, fieldModels, createItemProps, onChange, showInvalids, onClose) {
    return groupedFieldModels.map((fieldModel) => {
      return this._renderField(
        fieldModel,
        fieldModels,
        createItemProps,
        onChange,
        showInvalids,
        onClose)
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

  _renderFieldsGroup(groupFields, fieldModels, createItemProps, onChange, showInvalids, onClose) {

    return (

      <section className='padding-bottom-l' key={groupFields.group}>

        {this._renderGroupNameIfNeeded(groupFields.group)}

        <div className='row group-of-fields'>

          {this._renderFieldsInGroup(
            groupFields.fieldModels,
            fieldModels,
            createItemProps,
            onChange,
            showInvalids,
            onClose)}

        </div>

      </section>
    )
  },



  _renderFieldsGrouped(fields, fieldModels, leftOrRight, createItemProps, onChange, showInvalids, onClose) {

    return _.map(
      LeftOrRightColumn._columnGroupFieldModels(fields, fieldModels, leftOrRight),
      (groupFields) => {
        return RenderCreateItem._renderFieldsGroup(groupFields,
          fieldModels,
          createItemProps,
          onChange,
          showInvalids,
          onClose)
      }
    )
  },



  _renderLeftColumn(fields, fieldModels, createItemProps, onChange, showInvalids, onClose) {

    return (
      <div className='col1of2 padding-right-xs' id='item-form-left-side'>
        {this._renderFieldsGrouped(fields, fieldModels, 'left', createItemProps, onChange, showInvalids, onClose)}
      </div>
    )
  },

  _renderRightColumn(fields, fieldModels, createItemProps, onChange, showInvalids, onClose) {
    return (
      <div className='col1of2' id='item-form-right-side'>
        {this._renderFieldsGrouped(fields, fieldModels, 'right', createItemProps, onChange, showInvalids, onClose)}
      </div>
    )
  },


  _renderColumns(fields, fieldModels, createItemProps, onChange, showInvalids, onClose) {
    return (
      <div id='flexible-fields'>
        {this._renderLeftColumn(fields, fieldModels, createItemProps, onChange, showInvalids, onClose)}
        {this._renderRightColumn(fields, fieldModels, createItemProps, onChange, showInvalids, onClose)}
      </div>
    )
  }


}
