(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.BasicAutocomplete = window.createReactClass({
    propTypes: {
    },

    displayName: 'BasicAutocomplete',

    getInitialState () {
      return {
        term: (this.props.initialText ? this.props.initialText : ''),
        result: null
      }
    },

    _callback(result) {
      if(this.props.onChange) {
        this.props.onChange(result)
      }
    },

    _onFocus() {
      if(!this.state.result) {
        this.debouncedMakeCall()
      }
    },

    _onSelect(row) {

      var term = row.label
      if(this.props.resetAfterSelection) {
        term = ''
      }

      this.setState({
        result: null,
        term: term
      })

      var l = window.lodash
      this._callback({
        term: row.label,
        id: row.id,
        value: l.cloneDeep(row.value)
      })

    },

    _onTerm(term) {
      this.setState(
        {term: term},
        this.debouncedMakeCall
      )

      this._callback({
        term: term,
        id: null
      })
    },

    componentDidMount() {
      this.debouncedMakeCall = _.debounce(this._makeCall, 100)
    },

    _makeCall() {
      this.props._makeCall(
        this.state.term,
        (result) => {
          this.setState({
            result: result
          })
        }
      )
    },

    // public methods
    // mirror jQueryAutocomplete API (for BarcodeScanner)
    val(str) {
      this._onTerm(str)
    },

    render () {
      var result = null
      var hasMore = null
      if(this.state.result) {
        result = _.first(this.state.result, 100)
        if(this.state.result.length > result.length) {
          hasMore = this.state.result.length - result.length
        }
      }
      return (
        <BasicAutocompleteInternals
          inputClassName={this.props.inputClassName}
          element={this.props.element}
          inputId={this.props.inputId}
          dropdownWidth={this.props.dropdownWidth}
          label={this.props.label}
          term={this.state.term}
          result={result}
          hasMore={hasMore}
          _onFocus={this._onFocus}
          _onTerm={this._onTerm}
          _onSelect={this._onSelect}
          name={this.props.name}
          wrapperStyle={this.props.wrapperStyle}
          liARenderer={this.props.liARenderer}
        />
      )
    }
  })
})()
