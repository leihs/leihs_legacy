(() => {
  const React = window.React

  window.FieldEditor = window.createReactClass({
    propTypes: {
    },

    displayName: 'FieldEditor',

    getInitialState () {

      return {
        ajaxLoadResult: null,
        fieldInput: null,
        editLoading: true,
        headerErrors: []
      }
    },



    renderEditButton(fieldId) {
      return (
        <div className='col-sm-2 text-right line-actions'>
          <a onClick={(e) => this.onEditClick(event, fieldId)} className='btn btn-default'>
            Editieren
          </a>
        </div>
      )
    },


    renderTitle() {
      return (
        <div className='panel'>
          <div className='row'>
            <div className='col-sm-6'>
              <h1>Feld Editor</h1>
            </div>

            <div className='col-sm-6 text-right'>
              <a onClick={e => this.onClickCreate(e)} className='btn btn-default'>
                <i className='fa fa-plus'></i>
                {' '}
                Feld erstellen
              </a>
            </div>
          </div>
        </div>
      )
    },



    cancelEdit(event) {
      event.preventDefault()
      this.props.close()
    },

    editMode() {
      return this.props.editFieldId ? true : false
    },

    renderEditFieldTitle() {

      if(this.editMode()) {
        var field = this.state.ajaxLoadResult.field
        return (
          <div className='col-sm-8'>
            <h1>Edit Field {'\'' + field.data.label + '\''}</h1>
          </div>
        )
      } else {
        return (
          <div className='col-sm-8'>
            <h1>New Field</h1>
          </div>
        )
      }

    },



    readFieldFromInputs() {

      if(this.editMode()) {
        if(this.state.ajaxLoadResult.field.dynamic) {
          return FieldForm2Entity.readEditDynamic(this.state.ajaxLoadResult.field, this.state.fieldInput)
        } else {
          return FieldForm2Entity.readEditStatic(this.state.ajaxLoadResult.field, this.state.fieldInput)
        }
      } else {
        return FieldForm2Entity.readNew(this.state.fieldInput)
      }

    },

    ajaxConfig() {

      if(this.editMode()) {
        return {
          path: this.props.parentProps.update_path,
          type: 'POST'
        }
      } else {
        return {
          path: this.props.parentProps.new_path,
          type: 'PUT'
        }
      }

    },

    validValues() {
      if(!this.state.fieldInput.values) {
        return true
      }

      var vs = _.map(this.state.fieldInput.values, (v) => v.value)

      return _.size(vs) == _.size(_.uniq(vs))
    },

    validateInputs() {

      var errors = []

      if(!this.editMode() && !this.state.fieldInput.id.trim().length > 0) {
        errors.push('Attribute is mandatory.')
      }

      if(!this.state.fieldInput.label.trim().length > 0) {
        errors.push('Name is mandatory.')
      }

      if(!this.validValues()) {
        errors.push('Values must be distinct.')
      }

      this.setState({
        headerErrors: errors
      })

      return errors.length == 0

    },


    saveEditField() {

      if(!this.validateInputs()) {
        return;
      }

      var field = this.readFieldFromInputs()

      var config = this.ajaxConfig()

      $.ajax({
        url: config.path,
        contentType: 'application/json',
        dataType: 'json',
        method: config.type,
        data: JSON.stringify({
          field: field
        })
      }).done((data) => {

        if(data.result == 'field-exists-already') {
          this.setState({
            headerErrors: ['Ein Feld mit dieser Id existiert schon.']
          })
        } else {
          this.props.close()
        }

      }).error((data) => {
        this.setState({
          headerErrors: ['Ein unerwarteter Fehler ist aufgetreten.']
        })
      })
    },

    renderEditFieldButtons() {
      return (
        <div className='col-sm-4 text-right'>
          <a onClick={(e) => this.cancelEdit(e)} className='btn btn-default'>Abbrechen</a>
          {' '}
          <button onClick={(e) => this.saveEditField()} className='btn btn-success' type='submit'>Speichern</button>
        </div>
      )
    },

    renderEditFieldHeader() {
      return (
        <div className='row' style={{marginBottom: '40px'}}>
          {this.renderEditFieldTitle()}
          {this.renderEditFieldButtons()}
        </div>
      )
    },

    renderEditFieldFlash() {

      if(this.state.headerErrors && this.state.headerErrors.length > 0) {
        return (
          <h4 className='alert alert-danger error'>
            <ul>
              {this.state.headerErrors.map((e, i) => <li key={'error_' + i}>{e}</li>)}
            </ul>
          </h4>
        )

      } else {
        return null
      }

    },

    mergeInput(event, attribute) {
      event.preventDefault()
      var value = event.target.value
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput[attribute] = value
          return next
        }
      )
    },

    mergeOwner(event) {
      var value = event.target.checked
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.owner = value
          return next
        }
      )

    },

    mergeCheckbox(event, attribute) {
      var value = event.target.checked
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput[attribute] = value
          return next
        }
      )
    },


    mergePackages(event) {
      var value = event.target.checked
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.packages = value
          return next
        }
      )
    },

    mergeRole(event) {
      event.preventDefault()
      var value = event.target.value
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.role = value
          return next
        }
      )
    },

    mergeSelect(event, attribute) {
      event.preventDefault()
      var value = event.target.value
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput[attribute] = value

          if(attribute == 'type') {
            if(value == 'radio' || value == 'select' || value == 'checkbox') {
              next.fieldInput.values = [{label: '', value: '', existing: false}]
              next.fieldInput.defaultValue = 0
            } else {
              next.fieldInput.values = undefined
              next.fieldInput.defaultValue = undefined
            }
          }
          return next
        }
      )
    },

    mergeValuesLabel(event, index) {
      event.preventDefault()
      var value = event.target.value
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.values[index].label = value
          return next
        }
      )
    },

    mergeValuesValue(event, index) {
      event.preventDefault()
      var value = event.target.value
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.values[index].value = value
          return next
        }
      )
    },

    removeValuesValue(event, index) {
      event.preventDefault()
      this.setState(
        (previous) => {
          next = _.clone(previous)
          if(next.fieldInput.defaultValue == index) {
            next.fieldInput.defaultValue = 0
          }
          next.fieldInput.values = _.reject(next.fieldInput.values, (v, i) => i == index)
          return next
        }
      )
    },

    addValuesValue(event) {
      event.preventDefault()
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.values.push({label: '', value: '', existing: false})
          return next
        }
      )
    },

    idExistsAlready() {
      return !_.isEmpty(_.filter(
        this.props.fields,
        (field) => {
          return field.id == 'properties_' + this.state.fieldInput.id
        }
      ))
    },

    renderIdInput() {


      if(this.editMode()) {

        return (
          <div className='col-sm-9'>
            {this.props.editFieldId}
          </div>
        )


      } else {

        var idHint = null
        if(this.idExistsAlready()) {
          idHint = <div style={{color: 'red'}}>{'Feld mit der Id properties_' + this.state.fieldInput.id + ' existiert schon.'}</div>
        }


        return (
          <div className='col-sm-9'>
            <div style={{display: 'inline-block', position: 'absolute', paddingTop: '9px'}}>properties_</div>
            <div style={{display: 'inline-block', width: '100%', paddingLeft: '75px'}}>
              <input onChange={(e) => this.mergeInput(e, 'id')} className='form-control' type='text' value={this.state.fieldInput.id} />
            </div>

            {idHint}
          </div>
        )

      }

    },

    changeDefaultValueRadio(event, index) {

      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.defaultValue = index
          return next
        }
      )

    },


    renderValue(v, i, last, defaultValue) {

      var renderMinus = (i, last) => {

        if(v.existing && this.state.ajaxLoadResult.items_count > 0) {
          return null
        }

        if(last && i == 0) {
          return null
        }
        return (
          <a onClick={(e) => this.removeValuesValue(e, i)} className='btn btn-default'>-</a>
        )
      }

      var renderPlus = (last) => {

        if(!last) {
          return null
        }

        return (
          <a onClick={(e) => this.addValuesValue(e)} className='btn btn-default'>+</a>
        )
      }

      var disableValueInput = this.editMode() && v.existing

      var renderDefaultRadio = () => {
        if(this.state.fieldInput.type == 'checkbox') {
          return null
        }

        return (
          <div className='col-sm-1' style={{textAlign: 'right'}}>
            <input onChange={(e) => this.changeDefaultValueRadio(e, i)} value={'default_radio_' + i} name={'default_radio_' + i} checked={i == defaultValue} type='radio' />
          </div>
        )

      }

      var valueColSpan = 'col-sm-4'
      if(this.state.fieldInput.type == 'checkbox') {
        valueColSpan = 'col-sm-5'
      }



      return (
        <div key={'value_' + i} className='row form-group'>
          {renderDefaultRadio()}
          <div className='col-sm-5'>
            <input onChange={(e) => this.mergeValuesLabel(e, i)} className='form-control' type='text' value={v.label} />
          </div>
          <div className={valueColSpan}>
            <input disabled={disableValueInput} onChange={(e) => this.mergeValuesValue(e, i)} className='form-control' type='text' value={v.value} />
          </div>
          <div className='col-sm-2 line-actions'>
            {renderMinus(i, last)}
            {renderPlus(last)}
          </div>
        </div>

      )


    },


    renderValuesBox() {


      if(!FieldForm2Entity.isInputMulti(this.state.fieldInput)) {
        return null
      }

      var values = this.state.fieldInput.values
      var defaultValue = this.state.fieldInput.defaultValue

      var renderDefault = () => {
          if(this.state.fieldInput.type == 'checkbox') {
            return null
          }

          return (
            <div className='col-sm-1' style={{textAlign: 'right'}}>
              <strong>Default</strong>
            </div>
          )
      }

      var valueColSpan = 'col-sm-4'
      if(this.state.fieldInput.type == 'checkbox') {
        valueColSpan = 'col-sm-5'
      }

      var header = (
        <div key={'header'} className='row form-group' style={{marginTop: '20px'}}>
          {renderDefault()}
          <div className='col-sm-5'>
            <strong>Im GUI Angezeigter Wert</strong>
          </div>
          <div className={valueColSpan}>
            <strong>In Datenbank gespeicherter Wert</strong>
          </div>
          <div className='col-sm-2 line-actions'>
          </div>
        </div>

      )

      return [header].concat(values.map((v, i) => {
        return this.renderValue(v, i, values.length - 1 == i, defaultValue)
      }))

    },


    deleteEditField(event) {
      event.preventDefault()

      var fieldId = this.props.editFieldId

      $.ajax({
        url: this.props.parentProps.fields_path + '/' + fieldId,
        contentType: 'application/json',
        dataType: 'json',
        method: 'DELETE'
      }).done((data) => {

        this.props.close()

      }).error((data) => {

      })
    },


    renderDeleteField() {

      if(!this.editMode()) {
        return null
      }

      var itemsCount = this.state.ajaxLoadResult.items_count
      if(itemsCount == 0) {

        return (
          <div className='row form-group'>
            <div className='col-sm-3' style={{paddingBottom: '60px'}}>
              <strong>This field is not used by any items/licenses:</strong>
            </div>
            <div className='col-sm-9'>
              <button onClick={(e) => this.deleteEditField(e)} className='btn btn-danger' type='submit'>Delete</button>
            </div>
          </div>
        )

      } else {

        return (
          <div className='row form-group'>
            <div className='col-sm-12' style={{paddingBottom: '30px'}}>
              <strong>This field is used by {itemsCount} items/licenses.</strong>
            </div>
          </div>
        )
      }




    },

    groups() {
      return _.sortBy(
        this.state.ajaxLoadResult.groups,
        (g) => (g ? g : '')
      )
    },

    onChangeGroup(event) {
      var value = event.target.value
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.newGroupSelected = false
          next.fieldInput.group = value
          return next
        }
      )
    },

    onChangeNewGroup(event) {
      this.setState(
        (previous) => {
          next = _.clone(previous)
          next.fieldInput.newGroupSelected = true
          return next
        }
      )
    },

    renderGroup(g, i) {
      var string = (g == null ? '' : g)
      return (
        <label key={'group_' + g} style={{float: 'left', width: '200px', fontWeight: 'normal'}}>
          <div style={{width: '30px', float: 'left'}}>
            <input onChange={(e) => this.onChangeGroup(e)} value={string} name={'radio_' + i} checked={string == this.state.fieldInput.group && !this.state.fieldInput.newGroupSelected} type='radio' />
          </div>
          <div style={{width: '160px', float: 'left'}}>
            {(string == '' ? <span style={{fontStyle: 'italic'}}>Keine</span> : string)}
          </div>
        </label>
      )

    },

    changeGroupInput(event) {
      event.preventDefault()
      var value = event.target.value
      this.setState(
        (previous) =>  {
          var next = _.clone(previous)
          next.fieldInput.groupInput = value
          return next
        }
      )
    },

    renderGroupInput() {
      return (
        <label key={'group_input'} style={{float: 'left', width: '400px', fontWeight: 'normal'}}>
          <div style={{width: '30px', float: 'left'}}>
            <input onChange={(e) => this.onChangeNewGroup(e)} value={'radio_input'} name={'radio_input'} checked={this.state.fieldInput.newGroupSelected} type='radio' />
          </div>
          <div style={{width: '360px', float: 'left'}}>


            <input onChange={(e) => this.changeGroupInput(e)} type='text' value={this.state.fieldInput.groupInput} />
          </div>
        </label>
      )
    },

    renderGroups() {
      return this.groups().map((g, i) => {
        return this.renderGroup(g, i)
      }).concat([
        this.renderGroupInput()
      ])
    },

    renderGroupForm() {
      return (
        <div className='row form-group'>
          <div className='col-sm-3'>
            <strong>Group</strong>
          </div>
          <div className='col-sm-9'>
            {this.renderGroups()}
          </div>
        </div>
      )
    },


    renderEditStatic() {

      var isMandatory = () => {
        return this.state.ajaxLoadResult.field.data.required
      }

      var renderActiveInput = () => {
        if(isMandatory()) {
          return <input defaultChecked={true} disabled type='checkbox' />
        } else {
          return <input onChange={(e) => this.mergeCheckbox(e, 'active')} checked={this.state.fieldInput.active} autoComplete='off' type='checkbox' />
        }
      }


      return (
        <div className='row'>
          <div className='col-sm-12'>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Attribute *</strong>
              </div>
              <div className='col-sm-9'>
                {this.props.editFieldId}
              </div>
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Name *</strong>
              </div>
              <div className='col-sm-9'>
                <input onChange={(e) => this.mergeInput(e, 'label')} className='form-control' type='text' value={this.state.fieldInput.label} />
              </div>
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Mandatory</strong>
              </div>
              <div className='col-sm-9'>
                {(isMandatory() ? 'Yes' : 'No')}
              </div>
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Active</strong>
              </div>
              <div className='col-sm-9'>
                {renderActiveInput()}
              </div>
            </div>
          </div>
        </div>
      )
    },

    renderEditDynamicOrNew() {
      return (
        <div className='row'>
          <div className='col-sm-12'>
            {this.renderDeleteField()}
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Attribute *</strong>
              </div>
              {this.renderIdInput()}
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Name *</strong>
              </div>
              <div className='col-sm-9'>
                <input onChange={(e) => this.mergeInput(e, 'label')} className='form-control' type='text' value={this.state.fieldInput.label} />
              </div>
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Active</strong>
              </div>
              <div className='col-sm-9'>
                <input onChange={(e) => this.mergeCheckbox(e, 'active')} checked={this.state.fieldInput.active} autoComplete='off' type='checkbox' />
              </div>
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Packages</strong>
              </div>
              <div className='col-sm-9'>
                <input onChange={(e) => this.mergePackages(e)} checked={this.state.fieldInput.packages} type='checkbox' />
              </div>
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Owner (edit)</strong>
              </div>
              <div className='col-sm-9'>
                <input onChange={(e) => this.mergeOwner(e)} checked={this.state.fieldInput.owner} type='checkbox' />
              </div>
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Role (view)</strong>
              </div>
              <div className='col-sm-9'>
                <select value={this.state.fieldInput.role} onChange={(e) => this.mergeRole(e)}>
                  <option value='lending_manager'>Lending Manager</option>
                  <option value='inventory_manager'>Inventory Manager</option>
                </select>
              </div>
            </div>
            {this.renderGroupForm()}
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Target</strong>
              </div>
              <div className='col-sm-9'>
                <select value={this.state.fieldInput.target} onChange={(e) => this.mergeSelect(e, 'target')}>
                  <option value='both'>Beides</option>
                  <option value='item'>Gegenstand</option>
                  <option value='license'>Lizenz</option>
                </select>
              </div>
            </div>
            <div className='row form-group'>
              <div className='col-sm-3'>
                <strong>Type</strong>
              </div>
              <div className='col-sm-9'>
                <select value={this.state.fieldInput.type} disabled={this.editMode()} onChange={(e) => this.mergeSelect(e, 'type')}>
                  <option value='text'>Text</option>
                  <option value='date'>Date</option>
                  <option value='select'>Select</option>
                  <option value='textarea'>Textarea</option>
                  <option value='radio'>Radio</option>
                  <option value='checkbox'>Checkbox</option>
                </select>
                {this.renderValuesBox()}
              </div>
            </div>
          </div>
        </div>
      )
    },


    renderEditFieldForm() {

      if(this.editMode() && !this.state.ajaxLoadResult.field.dynamic) {
        return this.renderEditStatic()
      } else {
        return this.renderEditDynamicOrNew()
      }
    },

    componentDidMount() {
      if(this.props.editFieldId) {
        this.loadEdit()
      } else {
        this.loadCreate()
      }

    },

    getAjax(url, data, callback) {
      $.ajax({
        url: url,
        contentType: 'application/json',
        dataType: 'json',
        method: 'GET',
        data: data
      }).done((data) => {
        callback(data)

      }).error((data) => {

      })
    },

    loadCreate() {
      this.getAjax(
        this.props.parentProps.groups_path,
        {},
        (data) => {
          this.setState({
            ajaxLoadResult: data,
            fieldInput: FieldEntity2Form.createFieldInput(),
            editLoading: false
          })
        }
      )
    },

    loadEdit() {
      this.getAjax(
        this.props.parentProps.single_field_path,
        {id: this.props.editFieldId},
        (data) => {
          this.setState({
            ajaxLoadResult: data,
            fieldInput: FieldEntity2Form.editFieldInput(data.field),
            editLoading: false
          })
        }
      )
    },

    render () {
      if(this.state.editLoading) {
        return (
          <div></div>
        )
      }

      return (
        <div style={{marginBottom: '100px'}}>
          {this.renderEditFieldFlash()}
          {this.renderEditFieldHeader()}
          {this.renderEditFieldForm()}
        </div>
      )
    }
  })
})()
