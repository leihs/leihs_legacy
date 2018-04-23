(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM

  window.ManageFields = window.createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        disabledFields: _.map(this.props.disabled_fields, (df) => df.field_id)
      }
    },

    isDisabled(field) {
      return _.find(this.state.disabledFields, (df) => df == field.id)
    },

    disable(disable, fieldId) {
      this.setState((old) => {
        var next = _.clone(old)
        if(disable) {
          next.disabledFields = _.uniq(old.disabledFields.concat(fieldId))
        } else {
          next.disabledFields = _.reject(old.disabledFields, (df) => df == fieldId)
        }
        return next
      }, () => {
        this.sendDisable(disable, fieldId)
      })
    },

    postAjax(url, data, callback) {
      $.ajax({
        url: url,
        contentType: 'application/json',
        dataType: 'json',
        method: 'POST',
        data: JSON.stringify(data)
      }).done((data) => {
        callback(data)

      }).error((data) => {

      })
    },

    sendDisable(disable, fieldId) {
      this.postAjax(
        '/manage/' + this.props.inventory_pool_id + '/disable_field',
        {
          disable: disable,
          field_id: fieldId,
          inventory_pool_id: this.props.inventory_pool_id
        },
        (data) => {

        }
      )
    },

    renderAction(field) {
      if(this.isDisabled(field)) {
        return <a onClick={(e) => this.disable(false, field.id)} className='button white'>{_jed('Enable')}</a>
      } else {
        return <a onClick={(e) => this.disable(true, field.id)} className='button white'>{_jed('Disable')}</a>
      }
    },

    renderStatus(field) {
      if(this.isDisabled(field)) {
        return <span style={{color: 'red'}}>{_jed('disabled')}</span>
      } else {
        return <span style={{color: 'green'}}>{_jed('enabled')}</span>
      }
    },

    renderTarget(field) {
      if(field.target_type == 'license') {
        return _jed('for licenses')
      } else if(field.target_type == 'item'){
        return _jed('for items')
      } else {
        return null
      }
    },

    renderFields() {
      return _.map(
        this.props.fields,
        (field) => {
          return (
            <div className='row line' key={field.id}>
              <div className='col1of6 line-col'>
                <strong>{_jed(field.label)}</strong>
              </div>
              <div className='col2of6 line-col' style={{textAlign: 'left'}}>
                {field.id}
              </div>
              <div className='col1of6 line-col' style={{textAlign: 'left'}}>
                {this.renderTarget(field)}
              </div>
              <div className='col1of6 line-col' style={{textAlign: 'left'}}>
                {this.renderStatus(field)}
              </div>
              <div className='col1of6 line-col line-actions'>
                {this.renderAction(field)}
              </div>
            </div>
          )
        }
      )
    },

    render () {

      return (
        <div className='row content-wrapper min-height-xl min-width-full straight-top'>
          <div className='list-of-lines'>
            {this.renderFields()}
          </div>
        </div>
      )
    }
  })
})()
