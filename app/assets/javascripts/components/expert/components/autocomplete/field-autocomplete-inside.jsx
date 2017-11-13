(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.FieldAutocompleteInside = window.createReactClass({
    propTypes: {
    },

    getInitialState() {
      return {
        keyIndex: - 1
      }
    },

    updateKeyIndex(keyIndex) {
      this.makeValidKeyIndex(this.props, keyIndex)
    },

    makeValidKeyIndex(props, keyIndex) {

      if(props.result) {
        if(keyIndex >= props.result.length) {
          keyIndex = props.result.length - 1
        }
        if(keyIndex <= 0) {
          keyIndex = 0
        }

        this.setState({
          keyIndex: keyIndex
        })

      } else {
        this.setState({
          keyIndex: - 1
        })
      }
    },

    componentWillReceiveProps(nextProps) {
      this.makeValidKeyIndex(nextProps, this.state.keyIndex)
    },

    _onKeyPress(event) {

      if(!this.props.result) {
        return
      }

      if(event.keyCode == 40) {
        event.preventDefault()
        this.updateKeyIndex(this.state.keyIndex + 1)
      }
      else if(event.keyCode == 38) {
        event.preventDefault()
        this.updateKeyIndex(this.state.keyIndex - 1)
      }
      else if(event.keyCode == 13) {
        event.preventDefault()
        var keyIndex = this.state.keyIndex
        if(keyIndex != - 1) {

          var row = this.props.result[keyIndex]

          this.reference.blur()

          this.props._onSelect({
            label: _jed(row.label),
            id: row.id
          })
        }
      }
    },

    _onFocus(event) {
      this.props._onFocus()
    },

    _onChange(event) {
      event.preventDefault()
      this.props._onTerm(event.target.value)
    },

    componentDidMount() {
      document.addEventListener('mousedown', this._handleClickOutside);
    },

    componentWillUnmount() {
      document.removeEventListener('mousedown', this._handleClickOutside);
    },

    _handleClickOutside(event) {
      if (this.ulReference && !this.ulReference.contains(event.target)) {
        this.props._onClose()
      }
    },

    _onSelect (event, row) {
      event.preventDefault()

      this.reference.blur()

      this.props._onSelect({
        label: _jed(row.label),
        id: row.id
      })
    },

    _lis() {
      return this.props.result.map((row, index) => {

        var className = 'separated-bottom exclude-last-child ui-menu-item'
        if(index == this.state.keyIndex) {
          className += ' ui-state-focus'
        }
        return (

          <li key={row.id} className={className} id='ui-id-227' tabIndex='-1' onMouseDown={(event) => this._onSelect(event, row)}>
            <a>
              <div className='row text-ellipsis' style={{width: '500px'}}>
                {_jed(row.label)}
              </div>
            </a>
          </li>
        )
      }.bind(this))
    },


    _ul () {


      if(this.props.result.length == 0) {
        return null
      }

      return (
        <ul ref={(ref) => this.ulReference = ref} className='ui-autocomplete ui-front ui-menu ui-widget ui-widget-content'
          tabIndex='0' style={{display: 'block', width: this.props.dropdownWidth}}>
          {this._lis()}
        </ul>
      )
    },

    _dropdown() {
      if(!this.props.result) {
        this.ulRefernce = null
        return null
      } else {
        return (
          <div style={{position: 'relative'}}>
            {this._ul()}
          </div>
        )
      }
    },

    render () {
      const props = this.props

      var label = props.label

      var Element = this.props.element

      return (
        <Element className='row'>
          <input
            autoComplete='off'
            className={this.props.inputClassName}
            id={this.props.inputId}
            ref={(ref) => this.reference = ref}
            onChange={this._onChange} value={this.props.term}
            onFocus={this._onFocus}
            onKeyDown={this._onKeyPress}
            placeholder={label} title={label} type='text'
            name={this.props.name} />
          <div className='addon transparent'>
             <i className='arrow down'></i>
          </div>

          {this._dropdown()}
        </Element>
      )
    }
  })
})()
