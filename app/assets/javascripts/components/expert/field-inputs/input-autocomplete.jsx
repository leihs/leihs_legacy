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


    _parent(selectedValue) {


      return _.first(this.props.selectedValues.filter((other) => {
        return other.field.id == selectedValue.field.values_dependency_field_id
      }))
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

        var parent = this._parent(selectedValue)

        var url = field.values_url.replace('$$$parent_value$$$', parent.value.id)

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

        return (
          <FieldAutocompletePreload label={_jed(field.label)} preloadUrl={url}
            doDelayedSearch={doSearch} onChange={this._onChange}/>
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


        return (

          <FieldAutocomplete label={_jed(field.label)}
            doSearch={doSearch} onChange={this._onChange}/>

        )

      }





    }
  })
})()
