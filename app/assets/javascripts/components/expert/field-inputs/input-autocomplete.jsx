(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputAutocomplete = React.createClass({
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


      if(field.values_dependency_field_id) {

        var url = field.values_url.replace('$$$parent_value$$$', props.dependencyValue.value.id)

        var transformResult = (result) => {

          return result.map((entry) => {

            return {
              label: entry.name,
              id: entry.id

            }
          })


        }

        var data = field.values

        var searchInData = (data, term) => {

          return data.filter((field) => {

            return field.name.toLowerCase().indexOf(term.toLowerCase()) >= 0

          })

        }


        var doSearch = (data, term, callback) => {

          callback(
            transformResult(searchInData(data, term))
          )

        }

        var initialText = null
        if(selectedValue.value.id) {
          initialText = selectedValue.value.text
        }

        return (
          <FieldAutocompletePreload label={_jed(field.label)} preloadUrl={url}
            doDelayedSearch={doSearch} onChange={this._onChange}
            name={'item[' + selectedValue.field.id + ']'}
            initialText={initialText} />
        )

        console.log('url = ' + url)

      } else {


        var transformResult = (result) => {

          return result.map((entry) => {

            return {
              label: entry.label,
              id: entry.value

            }
          })


        }

        var data = field.values

        var searchInData = (term) => {

          return data.filter((field) => {

            return field.label.toLowerCase().indexOf(term.toLowerCase()) >= 0

          })

        }


        var doSearch = (term, callback) => {

          callback(
            transformResult(searchInData(term))
          )

        }


        var initialText = null
        if(selectedValue.value.id) {
          initialText = selectedValue.value.text
        }

        return (

          <FieldAutocomplete label={_jed(field.label)}
            initialText={initialText}
            doSearch={doSearch} onChange={this._onChange}
            name={'item[' + selectedValue.field.id + ']'} />

        )

      }





    }
  })
})()
