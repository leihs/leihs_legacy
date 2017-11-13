(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React

  window.HandOverDialog = window.createReactClass({
    propTypes: {
    },

    getInitialState () {
      return {
        showPurposeInput: (this._purpose() ? false : true),
        delegatedUser: null
      }
    },

    _userId() {
      return this.props.data.user.id
    },


    _title() {
      var itemsCount = this.props.data.itemsCount
      return _jed(itemsCount, 'Hand over of %s item', 'Hand over of %s items', itemsCount)
    },

    _username() {
      var user = this.props.data.user
      return user.firstname + ' ' + (user.lastname ? user.lastname : '')
    },

    _isUserDelegation() {
      return this.props.data.user.isDelegation()
    },


    _onDelegatedUser(user) {
      this.setState({
        delegatedUser: user
      })
      this.props.onDelegatedUser(user)
    },

    _renderContactPerson() {

      if(this._isUserDelegation()) {

        return (
          <div className='row margin-bottom-l'>
            <div className='col1of3' id='contact-person'>
              <ChooseUserPreload delegationId={this._userId()} delegatedUser={this.state.delegatedUser} onDelegatedUser={this._onDelegatedUser} />
            </div>
          </div>
        )
      } else {
        return null
      }
    },

    _purpose() {
      return this.props.data.purpose
    },


    _showAddPurposeButton() {
      return !this.state.showPurposeInput
    },


    _onAddPurpose() {
      this.setState({showPurposeInput: true})
    },


    _renderAddPurpose() {
      if(this._showAddPurposeButton()) {
        return (
          <button onClick={this._onAddPurpose} className='button inset' id='add-purpose'>{_jed('Add Purpose')}</button>
        )
      } else {
        return null
      }

    },

    _renderPurpose() {

      if(this._purpose()) {
        return (
          <div className='row margin-bottom-s emboss padding-inset-s'>
            <div className='col3of4'>
              <p className='paragraph-s'>{this._purpose()}</p>
            </div>
            <div className='col1of4 text-align-right'>
              {this._renderAddPurpose()}
            </div>
          </div>
        )
      } else {
        return null
      }
    },

    _renderProvidePurposeClass() {
      if(this.state.showPurposeInput) {
        return ''
      } else {
        return 'hidden'
      }
    },

    _date(date) {
      return moment(date).format(i18n.date.L)
    },

    _diffDatesInDays(start, end) {
      var ms = moment(start)
      var me = moment(end)
      var days = moment.duration(me.diff(ms)).days() + 1
      return days + ' ' + _jed('Days', 'Day', days)
    },

    _reservationName(reservation) {
      return reservation.model().name()
    },

    _subreservationQuantity(reservation) {
      return _.reduce(
        reservation.subreservations,
        (mem, r) => mem + r.quantity,
        0
      )
    },

    _reservationQuantity(reservation) {

      if(reservation.subreservations) {
        return this._subreservationQuantity(reservation)
      } else {
        return reservation.quantity
      }
    },

    _renderReservation(reservation, index) {

      return (
        <div key={'reservation_' + index} className='row'>
          <div className='col1of8 text-align-center'>
            <div className='paragraph-s'>
              {this._reservationQuantity(reservation)}
            </div>
          </div>
          <div className='col7of8'>
            <div className='paragraph-s'>
              <strong>{this._reservationName(reservation)}</strong>
            </div>
          </div>
        </div>
      )
    },

    _renderReservations(groupedLine) {

      return groupedLine.reservations.map((r, index) => {
        return this._renderReservation(r, index)
      })
    },

    _renderLine(groupedLine, index) {

      return (
        <div key={'grouped_line_' + index} className='padding-bottom-m margin-bottom-m no-last-child-margin'>
          <div className='row margin-bottom-s'>
            <div className='col1of2'>
              <p>
                {this._date(groupedLine.start_date)}
                {' - '}
                {this._date(groupedLine.end_date)}
              </p>
            </div>
            <div className='col1of2 text-align-right'>
              <strong>{this._diffDatesInDays(groupedLine.start_date, groupedLine.end_date)}</strong>
            </div>
          </div>
          {this._renderReservations(groupedLine)}
        </div>
      )
    },

    _renderLines() {

      return this.props.data.groupedLines.map((gl, index) => {
        return this._renderLine(gl, index)
      })
    },

    _defaultContractNote() {
      return this.props.other.currentInventoryPool.default_contract_note
    },

    render () {

      return (
        // NOTE: Here remove the wrapper element as soon as possible in the new React version.
        <div>
          <div className='modal-header row'>
            <div className='col3of5'>
              <h2 className='headline-l'>{this._title()}</h2>
              <h3 className='headline-m light'>
                {this._username()}
              </h3>
            </div>
            <div className='col2of5 text-align-right'>
              <div className='modal-close'>{_jed('Cancel')}</div>
              <button className='button green' data-hand-over>
                <i className='fa fa-mail-forward'></i>
                {_jed('Hand Over')}
              </button>
            </div>
          </div>
          <div className='row margin-top-s padding-horizontal-l'>
            <div className='separated-bottom padding-bottom-m margin-bottom-m'>
              <p className='emboss red padding-inset-s hidden paragraph-s margin-bottom-s' id='error'>
                <strong></strong>
              </p>
              {this._renderContactPerson()}
              {this._renderPurpose()}
              <div className={this._renderProvidePurposeClass()} id='purpose-input'>
                <div className='row padding-bottom-s'>
                  <p>{_jed('Please provide a purpose...')}</p>
                </div>
                <textarea className='row height-xs' id='purpose' name='purpose'></textarea>
              </div>
            </div>
            <div className='modal-body'>
              {this._renderLines()}
            </div>
            <div className='row separated-top padding-top-m padding-bottom-m'>
              <div className='col1of1 padding-bottom-s'>
                <p>{_jed('Write a note... the note will be part of the contract')}</p>
              </div>
              <textarea defaultValue={this._defaultContractNote()} className='col1of1 height-xs' id='note' name='note' />
            </div>
          </div>
        </div>
      )
    }
  })
})()
