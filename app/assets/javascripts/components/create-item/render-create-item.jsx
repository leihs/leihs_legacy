;(() => {
  /* global _ */
  /* global _jed */

  const React = window.React
  const LeftOrRightColumn = window.LeftOrRightColumn

  const RenderCreateItem = {
    _renderFieldContent(fieldModel, fieldModels, onChange, showInvalids, onClose, fieldRenderer) {
      var dependencyValue = _.first(
        _.filter(fieldModels, (other) => {
          return other.field.id == fieldModel.field.values_dependency_field_id
        })
      )

      var dataDependency = _.first(
        _.filter(fieldModels, (other) => {
          return other.field.id == fieldModel.field.data_dependency_field_id
        })
      )

      return fieldRenderer(
        fieldModel,
        fieldModels,
        onChange,
        showInvalids,
        onClose,
        dependencyValue,
        dataDependency
      )
    },

    _renderDependents(fieldModel, fieldModels, onChange, showInvalids, fieldRenderer) {
      if (!fieldModel.dependents) {
        return []
      }

      if (fieldModel.hidden) {
        return []
      }

      return fieldModel.dependents.map((dependent) => {
        return this._renderField(
          dependent,
          fieldModels,
          onChange,
          showInvalids,
          null,
          fieldRenderer
        )
      })
    },

    _renderField(fieldModel, fieldModels, onChange, showInvalids, onClose, fieldRenderer) {
      var _onClose = () => {
        onClose(fieldModel)
      }

      return (
        <div id={fieldModel.field.id} key={fieldModel.field.id}>
          {this._renderFieldContent(
            fieldModel,
            fieldModels,
            onChange,
            showInvalids,
            _onClose,
            fieldRenderer
          )}

          {this._renderDependents(fieldModel, fieldModels, onChange, showInvalids, fieldRenderer)}
        </div>
      )
    },

    _renderFieldsInGroup(
      groupedFieldModels,
      fieldModels,
      onChange,
      showInvalids,
      onClose,
      fieldRenderer
    ) {
      return groupedFieldModels.map((fieldModel) => {
        return this._renderField(
          fieldModel,
          fieldModels,
          onChange,
          showInvalids,
          onClose,
          fieldRenderer
        )
      })
    },

    _renderGroupNameIfNeeded(groupName) {
      if (groupName) {
        return <h2 className="headline-m padding-bottom-m">{_jed(groupName)}</h2>
      } else {
        return null
      }
    },

    _renderFieldsGroup(groupFields, fieldModels, onChange, showInvalids, onClose, fieldRenderer) {
      return (
        <section className="padding-bottom-l" key={groupFields.group}>
          {this._renderGroupNameIfNeeded(groupFields.group)}

          <div className="row group-of-fields">
            {this._renderFieldsInGroup(
              groupFields.fieldModels,
              fieldModels,
              onChange,
              showInvalids,
              onClose,
              fieldRenderer
            )}
          </div>
        </section>
      )
    },

    _renderFieldsGrouped(
      fields,
      fieldModels,
      leftOrRight,
      onChange,
      showInvalids,
      onClose,
      fieldRenderer
    ) {
      return _.map(
        LeftOrRightColumn._columnGroupFieldModels(fields, fieldModels, leftOrRight),
        (groupFields) => {
          return RenderCreateItem._renderFieldsGroup(
            groupFields,
            fieldModels,
            onChange,
            showInvalids,
            onClose,
            fieldRenderer
          )
        }
      )
    },

    _renderLeftColumn(fields, fieldModels, onChange, showInvalids, onClose, fieldRenderer) {
      return (
        <div className="col1of2 padding-right-xs" id="item-form-left-side">
          {this._renderFieldsGrouped(
            fields,
            fieldModels,
            'left',
            onChange,
            showInvalids,
            onClose,
            fieldRenderer
          )}
        </div>
      )
    },

    _renderRightColumn(fields, fieldModels, onChange, showInvalids, onClose, fieldRenderer) {
      return (
        <div className="col1of2" id="item-form-right-side">
          {this._renderFieldsGrouped(
            fields,
            fieldModels,
            'right',
            onChange,
            showInvalids,
            onClose,
            fieldRenderer
          )}
        </div>
      )
    },

    _renderColumns(fields, fieldModels, onChange, showInvalids, onClose, fieldRenderer) {
      return (
        <div id="flexible-fields">
          {this._renderLeftColumn(
            fields,
            fieldModels,
            onChange,
            showInvalids,
            onClose,
            fieldRenderer
          )}
          {this._renderRightColumn(
            fields,
            fieldModels,
            onChange,
            showInvalids,
            onClose,
            fieldRenderer
          )}
        </div>
      )
    }
  }

  window.RenderCreateItem = RenderCreateItem
  window.RenderCreateItem.displayName = 'RenderCreateItem'
})()
