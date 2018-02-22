(() => {
  const React = window.React

  window.FieldList = window.createReactClass({
    propTypes: {
    },

    displayName: 'FieldList',

    getInitialState () {
      return {
        showEdit: false,
        editFieldId: null,
        openFields: {},
        search: ''
      }
    },

    allFields() {
      return this.state.fields
    },

    isEditableField(field) {

      if(!field.dynamic) {
        return false
      }

      return _.contains(['text', 'date', 'select', 'textarea', 'radio', 'checkbox'], field.data.type)
    },

    searchResult(f) {

      var search  = this.state.search.toLowerCase()
      if(search.trim().length == 0) {
        return true
      }

      var label = f.data.label
      if(label.toLowerCase().indexOf(search) > - 1) {
        return true
      }

      var id = f.id
      if(id.toLowerCase().indexOf(search) > - 1) {
        return true
      }

      var group = f.data.group
      if(group && group.toLowerCase().indexOf(search) > - 1) {
        return true
      }

      return false

    },

    editableFields() {
      return _.filter(
        this.allFields(),
        (f) => this.isEditableField(f) && this.searchResult(f)
      )
    },

    staticFields() {
      return _.filter(
        this.allFields(),
        (f) => !this.isEditableField(f) && this.searchResult(f)
      )
    },

    onEditClick(event, fieldId) {
      event.preventDefault()
      this.setState({
        editFieldId: fieldId,
        showEdit: true
      })
    },

    renderEditButton(fieldId) {
      return (
        <div className='col-sm-4 text-right line-actions'>
          <a onClick={(e) => this.onEditClick(event, fieldId)} className='btn btn-default'>
            Editieren
          </a>
        </div>
      )
    },

    onClickCreate(event) {
      event.preventDefault()
      this.setState({
        showEdit: true,
        editFieldId: null,
      })
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


    toggleField(event, fieldId) {
      this.setState(
        (previous) => {
          return _.extend(
            previous,
            {
              openFields: _.extend(
                previous.openFields,
                {[fieldId]: (!previous.openFields[fieldId] ? true : false)}
              )
            }
          )
        }
      )
    },

    renderDetail(f) {
      if(!this.state.openFields[f.id]) {
        return null
      }

      return (
        <div className='col-sm-12' style={{marginTop: '10px', marginBottom: '30px'}}>
          <pre>
            {JSON.stringify(f, null, ' ')}
          </pre>
        </div>

      )
    },


    renderField(f) {
      return (
        <div key={'editable_field_' + f.id} className='row' style={{wordBreak: 'break-word', paddingTop: '15px', paddingBottom: '15px'}}>
          <div className='col-sm-8' style={{cursor: 'pointer'}} onClick={(e) => this.toggleField(e, f.id)}>
            <div>
              <strong>
                {f.data.label}
              </strong>
            </div>
            <div style={{color: '#b6b6b6'}}>
              {f.id}
            </div>
          </div>
          {this.renderEditButton(f.id)}
          {this.renderDetail(f)}
        </div>
      )
    },


    renderFields(fields) {
      return fields.map(f => {
        return this.renderField(f)
      })
    },


    renderEditableFields() {
      var fields = _.sortBy(this.editableFields(), (field) => field.data.label)
      return this.renderFields(fields)
    },

    renderStaticFields() {
      var fields = _.sortBy(this.staticFields(), (field) => field.data.label)
      return this.renderFields(fields)
    },

    renderEditableFieldsBox() {
      return (
        <div className='panel panel-default'>
          <div className='panel-heading'>
            <h4>Dynamische Felder</h4>
          </div>
          <div className='panel-body' style={{paddingTop: '0px', paddingBottom: '0px'}}>
            <div className='list-of-lines'>
              {this.renderEditableFields()}
            </div>
          </div>
        </div>
      )
    },

    renderStaticFieldsBox() {
      return (
        <div className='panel panel-default'>
          <div className='panel-heading'>
            <h4>Statische Felder</h4>
          </div>
          <div className='panel-body' style={{paddingTop: '0px', paddingBottom: '0px'}}>
            <div className='list-of-lines'>
              {this.renderStaticFields()}
            </div>
          </div>
        </div>
      )
    },

    search(event) {
      event.preventDefault()
      this.setState({
        search: event.target.value
      })
    },

    renderOverview() {

      if(this.state.loading) {
        return (
          <div></div>
        )
      }

      return (
        <div>
          {this.renderTitle()}
          <div className='col-sm-12' style={{marginBottom: '20px', paddingLeft: '0px', paddingRight: '0px'}}>
            <input value={this.state.search} onChange={(e) => this.search(e)} autoComplete='false' type='text' className='form-control' placeholder='Search for field id, label or group...' />
          </div>
          <div className='col-sm-6' style={{paddingLeft: '0px'}}>
            {this.renderEditableFieldsBox()}
          </div>
          <div className='col-sm-6' style={{paddingRight: '0px'}}>
            {this.renderStaticFieldsBox()}
          </div>
        </div>
      )

    },

    componentDidMount() {

      this.loadList()

    },

    loadList() {

      $.ajax({
        url: this.props.all_fields_path,
        contentType: 'application/json',
        dataType: 'json',
        method: 'GET',
        data: JSON.stringify({})
      }).done((data) => {
        this.setState({
          fields: data.fields,
          loading: false
        })

      }).error((data) => {

      })

    },

    closeEdit() {
      this.setState({
        showEdit: false,
        editFieldId: null,
        loading: true
      }, () => {
        this.loadList()
      })
    },

    render () {

      if(this.state.showEdit) {
        return (
          <FieldEditor
            parentProps={this.props}
            editFieldId={this.state.editFieldId}
            close={this.closeEdit}
          />
        )
      } else {
        return this.renderOverview()
      }

    }
  })
})()
