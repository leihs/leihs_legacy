(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React

  window.SwapOrderUserDialog = window.createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        input: '',
        selectedUser: null,
        hideDropdown: false,
        delegatedUser: null,
        userData: [],
        errors: null
      }
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
        this._onHideDropdown()
      }
    },

    _onHideDropdown() {
      this.setState({hideDropdown: true})
    },

    _onChangeInput(event) {
      this.setState(
        {
          input: event.target.value,
          hideDropdown: false
        },
        this._loadUsers
      )
    },


    _loadUsers() {

      if(this.state.input.length == 0) {
        this.setState({
          userData: []
        })
        return
      }

      var data = {
        search_term: this.state.input
      }

      if(this.ajaxCall) {
        this.ajaxCall.abort()
      }

      this.ajaxCall = $.ajax({
        url: App.User.url(),
        data: $.param(data),
        contentType: 'application/json',
        dataType: 'json',
        method: 'GET'
      }).done((data) => {

        _.each(data, (d) => {
          App.User.addRecord(new App.User(d))
        })

        this.setState({
          userData: data
        })
      })



    },


    _onClearUser() {
      this.setState({
        selectedUser: null,
        userData: [],
        delegatedUser: null
      })

    },

    _renderSelectedUser() {

      if(!this.state.selectedUser) {
        return null
      }

      return (
        <div className='emboss white padding-inset-xxs'>
          <div className='row'>
            <p className='paragraph-s'>
              <strong>
                {this.state.selectedUser.name}
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

    _userAddress(user) {
      return (user.address ? user.address : '')
        + ' '
        + (user.city ? user.city : '')
    },

    _onUserClick(event, user) {
      event.preventDefault()
      this.setState({selectedUser: user, input: ''})
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
      return this.state.userData
    },

    _renderDropdown() {

      var display = 'none'
      if(this._dropdownData().length > 0 && !this.state.selectedUser && !this.state.hideDropdown) {
        display = 'block'
      }

      return (
        <div style={{position: 'relative'}}>
          <ul ref={(ref) => this.ulReference = ref} id='ui-id-1' tabIndex='0' className='ui-menu ui-widget ui-widget-content ui-autocomplete ui-front ui-autocomplete-disabled' style={{display: display, top: '30px', left: '0px', width: '231px', top: '0px'}}>
            {this._renderDropdownLines()}
          </ul>
        </div>
      )
    },


    _onInputFocus() {
      this.setState({hideDropdown: false})
    },


    _renderDelegatedUser() {

      if(!this.props.other.order.delegated_user) {
        return null
      }

      var delegatedUser = App.User.find(this.props.other.order.delegated_user.id)

      return (
        <p className='paragraph-s padding-top-xxs margin-top-xxs'>
          <strong>
            {delegatedUser.firstname}
            {' '}
            {delegatedUser.lastname}
          </strong>
        </p>
      )
    },


    _onDelegatedUser(user) {
      this.setState({
        delegatedUser: user
      })
    },

    _currentUserId() {
      return this.state.selectedUser ? this.state.selectedUser.id : this.props.other.order.user().id
    },

    _renderContactPerson() {

      var currentUserId = this._currentUserId()

      if(!App.User.find(currentUserId).isDelegation()) {
        return null
      }

      return (

        <div className='row padding-vertical-m' id='contact-person'>
          <div className='row emboss padding-inset-m'>
            <div className='col4of9 text-align-center' id='swapped-person' style={{textAlign: 'left'}}>
              <ChooseUserPreload relative delegationId={currentUserId} delegatedUser={this.state.delegatedUser} onDelegatedUser={this._onDelegatedUser} />
            </div>
            <div className='col1of9 text-align-center'>
              <i className='fa fa-exchange icon-xxl'></i>
            </div>
            <div className='col4of9 text-align-center'>
              {this._renderDelegatedUser()}

            </div>
          </div>
        </div>


      )


    },

    _disableSubmit() {
      return !this.state.selectedUser
    },

    _onSubmit(event) {
      event.preventDefault()

      this._doSwapOrderUser()
    },

    _doSwapOrderUser() {

      this.setState({
        errors: null
      })

      var userId = this._currentUserId()
      var delegationId = null
      if(this.state.delegatedUser) {
        delegationId = this.state.delegatedUser.id
      }
      this.props.other.order.swapUser(
        userId, delegationId
      ).done(() => {
        window.location = this.props.other.order.editPath()

      }).fail((e) => {
        this.setState({
          errors: '' + e.responseText
        })

      })

    },

    render () {

      var displayInput = 'inline-block'
      if(this.state.selectedUser) {
        displayInput = 'none'
      }

      var disabledSubmit = 'disabled'
      if(!this._disableSubmit()) {
        disabledSubmit = null
      }
      disabledSubmit = null

      var errorsClass = 'padding-vertical-m'
      if(this.state.errors == null) {
        errorsClass += ' hidden'
      }

      return (
        <form>
          <div className='row padding-vertical-m'>
            <div className='col1of2'>
              <h3 className='headline-l'>{_jed('Change orderer')}</h3>
            </div>
            <div className='col1of2'>
              <div className='float-right'>
                <a aria-hidden='true' className='modal-close weak' data-dismiss='modal' title={_jed('close dialog')} type='button'>
                  {_jed('Cancel')}
                </a>
                <button onClick={this._onSubmit} disabled={disabledSubmit} className='button white text-ellipsis' type='submit'>
                  {_jed('Change orderer')}
                </button>
              </div>
            </div>
          </div>
          <div className={errorsClass} id='errors'>
            <div className='row emboss red text-align-center font-size-m padding-inset-s'>
              <strong>{this.state.errors}</strong>
            </div>
          </div>
          <div className='row padding-vertical-m' id='user'>
            <div className='row emboss padding-inset-m'>
              <div className='col4of9 text-align-center' style={{textAlign: 'left'}} id='swapped-person'>
                <input ref={(ref) => this.inputReference = ref} style={{display: displayInput}} onFocus={this._onInputFocus} value={this.state.input} onChange={this._onChangeInput} autoComplete='off' autoFocus='autofocus' className='width-m' data-barcode-scanner-target data-prevent-barcode-scanner-submit id='user-id' placeholder={_jed('Name / ID')} type='text' />
                <div id='selected-user'>
                  {this._renderSelectedUser()}
                </div>
                {this._renderDropdown()}
              </div>
              <div className='col1of9 text-align-center'>
                <i className='fa fa-exchange icon-xxl'></i>
              </div>
              <div className='col4of9 text-align-center'>
                <p className='paragraph-s padding-top-xxs margin-top-xxs'>
                  <strong>
                    {this.props.other.order.user().firstname}
                    {' '}
                    {this.props.other.order.user().lastname}
                  </strong>
                </p>
              </div>
            </div>
          </div>
          {this._renderContactPerson()}
        </form>
      )
    }
  })
})()
