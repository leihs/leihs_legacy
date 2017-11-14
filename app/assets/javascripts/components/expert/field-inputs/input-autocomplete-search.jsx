(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputAutocompleteSearch = React.createClass({
    propTypes: {
    },


    _onChange(result) {

      this.props.selectedValue.value = {
        text: result.term,
        id: result.id
      }
      this.props.onChange()
    },



    render () {
      const props = this.props
      const selectedValue = props.selectedValue


      var field = selectedValue.field

      var transformResult = (result) => {

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

      }

      var dataUrl = field.search_path

      var doSearch = (term, callback) => {

        if(term.trim() != '') {

          App.Model.ajaxFetch(
            {
              url: dataUrl,
              data: $.param({
                format: 'json',
                search_term: term
              })
            }
          ).done((data) => {
            callback(transformResult(data))
          })


        } else {
          callback(null)
        }

      }

      return (

        <FieldAutocomplete label={_jed(field.label)}
          doSearch={doSearch} onChange={this._onChange}
          name={this.props.name} initialText={selectedValue.value.text}/>

      )
    }
  })
})()
