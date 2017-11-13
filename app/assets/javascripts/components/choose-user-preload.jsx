(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React

  window.ChooseUserPreload = createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        userDataLoaded: false,
        personInput: '',
        userData: [],
        hideDropdown: false
      }
    },


    componentDidMount() {
      document.addEventListener('mousedown', this._handleClickOutside);
      this._loadUsers()
    },

    componentWillUnmount() {
      document.removeEventListener('mousedown', this._handleClickOutside);
    },

    _loadUsers() {

      App.User.ajaxFetch({
        data: $.param({
          delegation_id: this.props.delegationId
        })
      })
      .done((data) => {
        this.setState({userDataLoaded: true, userData: data})
      })
    },

    _onChangePersonInput(event) {
      this.setState({
        personInput: event.target.value,
        hideDropdown: false
      })
    },

    _onUserClick(event, user) {
      event.preventDefault()
      this.props.onDelegatedUser(user)
      this.setState({personInput: ''})
    },

    _userAddress(user) {
      return (user.address ? user.address : '')
        + ' '
        + (user.city ? user.city : '')
    },

    _renderDropdownLine(user) {
      return (
        <li key={user.id} className='separated-bottom exclude-last-child ui-menu-item'>
           <a onClick={(event) => this._onUserClick(event, user)} className='row ui-menu-item-wrapper' title='Christophe Besch' id='ui-id-62' tabIndex='-1'>
              <div className='row text-ellipsis'>
                <strong>
                  {user.name}
                </strong>
              </div>
              <div className='row text-ellipsis'>
                {this._userAddress(user)}
              </div>
           </a>
        </li>
      )
    },

    _renderDropdownLines() {
      return this._dropdownData().map((u) => {
        return this._renderDropdownLine(u)
      })
    },

    _dropdownData() {

      var input = this.state.personInput

      if(input == '') {
        return this.state.userData
      }

      var contains = (string, part) => {
        if(!string || !part) {
          return false
        }
        return string.toLowerCase().indexOf(part.toLowerCase()) > - 1
      }

      return _.filter(
        this.state.userData,
        (u) => {
          return contains(u.name, input) || contains(u.address, input) || contains(u.city, input)
        }
      )
    },


    _handleClickOutside(event) {
      if (this.ulReference && !this.ulReference.contains(event.target)
        && this.inputReference && !this.inputReference.contains(event.target)) {
        this._onHideDropdown()
      }
    },

    _onHideDropdown() {
      this.setState({hideDropdown: true})
    },

    _renderUl() {

      var display = 'none'
      if(this._dropdownData().length > 0 && !this.props.delegatedUser && !this.state.hideDropdown) {
        display = 'block'
      }

      var top = '30px'
      if(this.props.relative) {
        top = '0px'
      }

      return (
        <ul ref={(ref) => this.ulReference = ref} id='ui-id-1' tabIndex='0' className='ui-menu ui-widget ui-widget-content ui-autocomplete ui-front ui-autocomplete-disabled' style={{display: display, top: top, left: '0px', width: '231px'}}>
          {this._renderDropdownLines()}
        </ul>
      )

    },

    _renderDropdown() {

      if(this.props.relative) {
        // TODO Hacky way for correct position in certain cases.
        return (
          <div style={{position: 'relative'}}>
            {this._renderUl()}
          </div>
        )
      } else {
        return this._renderUl()
      }
    },


    _placeholder() {
      return _jed('Contact person') + ' ' + _jed('Name / ID')
    },

    _onClearUser() {
      this.props.onDelegatedUser(null)
      this.setState({delegatedUser: null})
    },

    _renderSelectedUser() {

      if(!this.props.delegatedUser) {
        return null
      }

      return (
        <div className='emboss white padding-inset-xxs'>
           <div className='row'>
              <p className='paragraph-s'>
                 <strong>
                   {this.props.delegatedUser.name}
                 </strong>
              </p>
              <div className='position-absolute-topright padding-inset-xxs'>
                 <a onClick={this._onClearUser} className='grey padding-inset-xxs' id='remove-user'>
                   <i className='fa fa-times-circle icon-m'></i>
                 </a>
              </div>
           </div>
        </div>
      )
    },

    _onInputFocus() {
      this.setState({hideDropdown: false})
    },


    render () {

      var display = 'inline-block'
      if(this.props.delegatedUser) {
        display = 'none'
      }


      return (
        // NOTE: Here remove the wrapper element as soon as possible in the new React version.
        <div>
          <input ref={(ref) => this.inputReference = ref} style={{display: display}} onFocus={this._onInputFocus} onChange={this._onChangePersonInput} value={this.state.personInput} autoComplete='off' autoFocus='autofocus' className='width-full' data-barcode-scanner-target data-prevent-barcode-scanner-submit id='user-id' placeholder={this._placeholder()} type='text' />
          <div id='selected-user'>
            {this._renderSelectedUser()}
          </div>
          {this._renderDropdown()}
        </div>
      )
    }
  })
})()
