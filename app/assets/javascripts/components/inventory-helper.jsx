(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this


  window.InventoryHelper = window.createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        fields: null,
      }
    },

    loadFields() {
      window.leihsAjax.getAjax(
        '/manage/' + this.props.inventory_pool_id + '/fields?target_type=item&exclude_checkbox=true',
        {},
        (status, response) => {
          this.setState({
            fields: response
          })
        }
      )
    },

    componentDidMount() {
      this.loadFields()
    },

    render () {

      if(!this.state.fields) {
        return (
          <div className='row content-wrapper min-height-xl min-width-full straight-top'>
            <div className='margin-top-l padding-horizontal-m'>
              <div className='row'>
                <h1 className='headline-xl'>{_jed('Inventory Helper')}</h1>
                <h2 className='headline-m light'>{_jed('Process multiple fields for multiple items in a row')}</h2>
              </div>
            </div>
          </div>
        )

      } else {

        return (
          <InventoryHelperFieldsLoaded {...this.props} fields={this.state.fields} />
        )
      }

    }
  })
})()
