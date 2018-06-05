(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputAutocompleteSearch = window.createReactClass({
    propTypes: {
    },


    _onChange(result) {

      this.abortAjaxCall()
      var l = window.lodash
      var value = l.cloneDeep(this.props.selectedValue.value)
      value.text = result.term
      value.id = result.id
      this.props.onChange(value)
    },

    ajaxCall: null,

    abortAjaxCall() {
      if(this.ajaxCall) {
        this.ajaxCall.abort()
      }
    },

    _transformResult(result) {

      return result.map((entry) => {

        var label = entry.product
        if(entry.version) {
          label += ' ' + entry.version
        }

        return {
          label: label,
          id: entry.id

        }
      })
    },

    _getField() {
      return this.props.selectedValue.field
    },

    _doSearch(term, callback) {

      var dataUrl = this._getField().search_path

      if(term.trim() != '') {

        this.abortAjaxCall()

        var params = {
          format: 'json',
          search_term: term
        }

        if(this.context.hackyForPackage && this._getField().id == 'model_id') {
          params.packages = 'true'
        }

        this.ajaxCall = $.ajax(
          {
            url: dataUrl,
            data: $.param(params)
          }
        ).done((data) => {
          callback(this._transformResult(data))
        })


      } else {
        callback(null)
      }


    },

    contextTypes: {
      hackyForPackage: PropTypes.bool
    },


    render () {
      const props = this.props
      const selectedValue = props.selectedValue

      return (
        <FieldAutocomplete label={_jed(this._getField().label)}
          doSearch={this._doSearch} onChange={this._onChange}
          name={this.props.name} initialText={selectedValue.value.text}/>
      )
    }
  })
})()
