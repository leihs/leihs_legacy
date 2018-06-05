(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.BasicAutocompleteInternals = window.createReactClass({
    propTypes: {
    },

    displayName: 'BasicAutocompleteInternals',

    getInitialState() {
      return {
        keyIndex: - 1,
        hideDropdown: false
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

          this.inputReference.blur()

          this.props._onSelect({
            label: _jed(row.label),
            id: row.id,
            value: row.value
          })
        }
      }
    },

    _onFocus(event) {
      this.props._onFocus()
      this.setState({hideDropdown: false})
    },

    _onClick(event) {
      this.props._onFocus()
      this.setState({hideDropdown: false})
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
      if (this.ulReference && !this.ulReference.contains(event.target)
        && this.inputReference && !this.inputReference.contains(event.target)) {
        this.setState({hideDropdown: true})
      }
    },

    _onSelect (event, row) {
      event.preventDefault()

      this.inputReference.blur()

      this.props._onSelect({
        label: _jed(row.label),
        id: row.id,
        value: row.value
      })
    },

    _li(row, index) {

      var className = 'separated-bottom exclude-last-child ui-menu-item'
      if(index == this.state.keyIndex) {
        className += ' ui-state-focus'
      }

      var liARenderer = null
      if(this.props.liARenderer) {
        liARenderer = this.props.liARenderer
      } else {
        liARenderer = (row) => {
          return (
            <a>
              <div className='row text-ellipsis' style={{width: '500px'}}>
                {row.label}
              </div>
            </a>
          )
        }
      }


      return (

        <li key={row.id} className={className} tabIndex='-1' onMouseDown={(event) => this._onSelect(event, row)}>
          {liARenderer(row)}
        </li>
      )


    },

    renderHasMore() {

      if(!this.props.hasMore) {
        return null
      } else {
        var className = 'separated-bottom exclude-last-child ui-menu-item'
        return (
          <li key={'has_more'} className={className} tabIndex='-1'>
            <div className='row text-ellipsis' style={{textAlign: 'center', fontStyle: 'italic', padding: '10px', color: '#aaa', cursor: 'default'}}>
              {_jed('has ' + this.props.hasMore + ' more...')}
            </div>
          </li>
        )
      }
    },


    _lis() {
      return _.compact(
        this.props.result.map((row, index) => {
          return this._li(row, index)
        }.bind(this)).concat(
          this.renderHasMore()
        )
      )
    },


    _ul () {


      if(this.props.result.length == 0 || this.state.hideDropdown) {
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
        <Element className='row' style={this.props.wrapperStyle}>
          <input
            autoComplete='off'
            className={this.props.inputClassName}
            id={this.props.inputId}
            ref={(ref) => this.inputReference = ref}
            onChange={this._onChange} value={this.props.term}
            onClick={this._onClick}
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
