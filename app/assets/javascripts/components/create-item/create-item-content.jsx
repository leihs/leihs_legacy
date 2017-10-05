(() => {

  const React = window.React

  window.CreateItemContent = React.createClass({
    propTypes: {
    },


    getInitialState() {
      return {
        fieldModels: this._createFieldModels(this.props.fields)
      }
    },


    _onlyMainFields(fields) {

      return fields.filter((f) => {
        return !f['visibility_dependency_field_id'] && !f['values_dependency_field_id']
      })
    },

    _createFieldModels(fields) {

      return this._onlyMainFields(fields).map((field) => {
          return {
              field: field,
              value: this._createEmptyValue(field),
              dependents: []
            }
        })
    },

    _getTodayAsString() {
      var today = new Date();
      var dd = today.getDate();
      var mm = today.getMonth() + 1;
      var yyyy = today.getFullYear();

      if(dd < 10) {
          dd = '0' + dd
      }
      if(mm < 10) {
          mm = '0' + mm
      }
      today = dd + '/' + mm + '/' + yyyy;

      return today
    },

    _createEmptyValue(field) {
      if(field.id == 'inventory_code') {
        return {text: this.props.createItemProps.next_code}
      } else if(field.id == 'owner_id') {
        return {
          text: this.props.createItemProps.inventory_pool.name,
          id: this.props.createItemProps.inventory_pool.id
        }
      } else if(field.id == 'last_check') {

        return {
          at: this._getTodayAsString()
        }
      } else {
        return CreateItemFieldSwitch._createEmptyValue(field)
      }
    },

    componentDidMount() {
      this._ensureDependents()
      this.setState({fieldModels: this.state.fieldModels})
    },

    _ensureDependents() {
      EnsureDependents._ensureDependents(this.state.fieldModels, this.props.fields, {
        _hasValue: CreateItemFieldSwitch._hasValue,
        _createEmptyValue: CreateItemFieldSwitch._createEmptyValue,
        _isDependencyValue: CreateItemFieldSwitch._isDependencyValue
      })
    },

    onChange() {
      this._ensureDependents()
      this.setState({fieldModels: this.state.fieldModels})
    },

    render () {

      return (
        <div className='padding-horizontal-m'>
          <div className='padding-vertical-m' id='notifications'></div>
          <form id='form'>
            <input disabled='disabled' name='copy' type='hidden' />
            {RenderCreateItem._renderColumns(this.props.fields, this.state.fieldModels, this.props.createItemProps,
              this.onChange, this.props.showInvalids)}
          </form>
        </div>
      )
    }
  })
})()
