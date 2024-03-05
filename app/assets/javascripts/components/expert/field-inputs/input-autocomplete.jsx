(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.InputAutocomplete = window.createReactClass({
    propTypes: {
    },



    _onChange(result) {

      var l = window.lodash
      var value = l.cloneDeep(this.props.selectedValue.value)
      value.text = result.term
      value.id = result.id
      this.props.onChange(value)
    },



    render () {
      const props = this.props
      const selectedValue = props.selectedValue





      var field = selectedValue.field


      if(field.values_dependency_field_id) {

        var url = field.values_url.replace('$$$parent_value$$$', props.dependencyValue.value.id)
        const formatLabel = entry =>  {
          if(field.id === 'room_id') {
            return entry.name + (!!entry.description ? ` (${entry.description})` : '')
          } else {
            return entry.name
          }
        }

        var doSearch = (data, term, callback) => {
          callback(
            data
              .map(entry => ({
                label: formatLabel(entry),
                id: entry.id
              }))
              .filter(entry => entry.label.toLowerCase().indexOf(term.toLowerCase()) >= 0)
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
