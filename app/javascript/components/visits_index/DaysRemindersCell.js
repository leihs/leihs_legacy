import React from 'react'
import { Popover } from 'react-bootstrap'
import ReactDOM from 'react-dom'
import f from 'lodash'

class DaysRemindersCell extends React.Component {
  constructor() {
    super()
    this.state = {
      reminderSent: false
    }
  }

  getMaxRange() {
    const max_ranges = []
    for (const reservation of this.props.v.reservations) {
      max_ranges.push(
        moment(reservation.end_date)
          .endOf('day')
          .diff(moment(reservation.start_date).startOf('day'), 'days')
      )
    }
    return 1 + max_ranges.reduce((a, b) => Math.max(a, b))
  }

  renderPopup() {
    const nofEmails = this.props.v.emails ? this.props.v.emails.length : 0
    return this.props.v.type === 'take_back' && this.props.isOverdue && nofEmails > 0
  }

  renderDaysCell() {
    const maxDays = this.getMaxRange()

    if (this.props.v.type !== 'take_back') {
      return (
        <div className="text-align-center">
          {maxDays} {_jed(maxDays, 'day', 'days')}
        </div>
      )
    }

    if (this.props.reminderSent) {
      return (
        <div className="latest-reminder-cell text-align-center tooltipstered">
          <strong>{`${_jed('Reminder sent')} `}</strong>
          <i className="fa fa-envelope" />
        </div>
      )
    }

    const nofEmails = this.props.v.emails ? this.props.v.emails.length : 0
    return (
      <div className="latest-reminder-cell text-align-center">
        {nofEmails > 0 ? `${nofEmails} ${_jed('Reminder emails')} ` : _jed('No reminder yet')}
        {nofEmails > 0 && <i className="fa fa-envelope-o" />}
      </div>
    )
  }

  diffToday(date) {
    if (
      moment()
        .startOf('day')
        .diff(moment(date).startOf('day'), 'days') == 0
    ) {
      return _jed('Today')
    } else {
      return moment(date)
        .startOf('day')
        .from(moment().startOf('day'))
    }
  }

  renderEmails() {
    const dateAndTime = date => {
      return `${this.diffToday(date)} ${moment(date).format('LT')}`
    }

    const { emails } = this.props.v
    if (!emails || emails.length === 0) {
      return <div className="row width-l paragraph-s"><center>{_jed('No reminder yet')}</center></div>
    }

    return (
      <div>
        {emails.length > 10 && <div>{_jed('Latest 10 emails')}</div>}
        {f.map(emails.slice(0, 10), email => {
          return (
            <div key={email.id} className="row width-l">
              <div className="paragraph-s">
                <strong>{dateAndTime(email.updated_at)}</strong>
                {` ${email.subject}`}
              </div>
            </div>
          )
        })}
      </div>
    )
  }

  render() {
    const hasPopup = this.renderPopup()
    return [
      hasPopup && (
        <Popup popupRef={this.popup} key={`reminder-popup-${this.props.v.id}`} trigger="click">
          <div style={{ opacity: '1' }} className="tooltipster-sidetip tooltipster-default tooltipster-top tooltipster-initial">
            <div className="tooltipster-box">
              <div className="tooltipster-content">
                {this.renderEmails()}
              </div>
            </div>
            <div className='tooltipster-arrow' style={{position: 'absolute', left: '0px', right: '0px', marginLeft: 'auto', marginRight: 'auto'}}>
              <div className='tooltipster-arrow-uncropped'>
                <div className='tooltipster-arrow-border'></div>
                <div className='tooltipster-arrow-background'></div>
              </div>
            </div>
          </div>
        </Popup>
      ),
      <div
        ref={ref => (this.popup = ref)}
        className={'col1of5 line-col' + (hasPopup ? ' click-popup' : '')}
        key={`reminder-${this.props.v.id}`}>
        {this.renderDaysCell()}
      </div>
    ]
  }
}

export default DaysRemindersCell
