import React from 'react'
import { Popover, Overlay } from 'react-bootstrap'
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
    return this.props.v.type == 'take_back' && (this.props.reminderSent || this.props.isOverdue)
  }

  renderDaysCell() {
    const maxDays = this.getMaxRange()

    let content
    if (this.props.v.type == 'take_back' && this.props.reminderSent) {
      content = (
        <div className="latest-reminder-cell text-align-center tooltipstered">
          <strong>{`${_jed('Reminder sent')} `}</strong>
          <i className="fa fa-envelope" />
        </div>
      )
    } else if (this.props.v.type == 'take_back' && this.props.isOverdue) {
      content = (
        <div className="latest-reminder-cell text-align-center">
          {_jed('Latest reminder')}
          <i className="fa fa-envelope-alt" />
        </div>
      )
    } else {
      content = (
        <div className="text-align-center">
          {maxDays} {_jed(maxDays, 'day', 'days')}
        </div>
      )
    }

    return content
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

  renderNotifications() {
    const dateAndTime = date => {
      return `${this.diffToday(date)} ${moment(date).format('LT')}`
    }

    return f.map(this.props.v.notifications, n => {
      return (
        <div key={n.id} className="row width-l">
          <div className="paragraph-s">
            <strong>{dateAndTime(this.props.v.date)}</strong>
            {` ${n.title}`}
          </div>
        </div>
      )
    })
  }

  render() {
    return [
      (this.renderPopup() && (
        <Popup popupRef={this.popup} key={`reminder-popup-${this.props.v.id}`}>
          <div style={{ opacity: '1' }} className="tooltipster-sidetip tooltipster-default tooltipster-top tooltipster-initial">
            <div className="tooltipster-box">
              <div className="tooltipster-content">
                {this.renderNotifications()}
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
      ))
      ,
      <div ref={ref => (this.popup = ref)} className="col1of5 line-col" key={`reminder-${this.props.v.id}`}>
        {this.renderDaysCell()}
      </div>
    ]
  }
}

export default DaysRemindersCell
