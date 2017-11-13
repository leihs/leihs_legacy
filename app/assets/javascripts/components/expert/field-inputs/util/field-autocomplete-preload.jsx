(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  React.findDOMNode = ReactDOM.findDOMNode

  window.FieldAutocompletePreload = window.createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        data: null
      }
    },

    componentDidMount () {

      App.Model.ajaxFetch(
        {
          url: this.props.preloadUrl,
          data: $.param({
            format: 'json'
          })
        }
      ).done((data) => {
        this.setState({data: data})
      })



    },


    render () {
      const props = this.props

      if(!this.state.data) {
        return (
          <div></div>
        )
      }

      var doSearch = (term, callback) => {
        this.props.doDelayedSearch(this.state.data, term, callback)
      }

      return (
        <FieldAutocomplete label={this.props.label}
          doSearch={doSearch} onChange={this.props.onChange}
          initialText={this.props.initialText}
          name={this.props.name} />
      )
    }
  })
})()
