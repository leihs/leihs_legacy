import React from 'react'
import ReservationsCell from './ReservationsCell'
import UserCell from './UserCell'
import DaysRemindersCell from './DaysRemindersCell'
const Flash = window.App.Flash

class VisitRow extends React.Component {
  constructor() {
    super()
    this.state = {
      deleted: false
    }
  }

  diffToday(date) {
    let tmp
    if (moment().startOf('day').diff(moment(date).startOf('day'), 'days') == 0) {
      tmp = _jed('Today')
    } else {
      tmp = moment(date).startOf('day').from(moment().startOf('day'))
    }
    return tmp
  }

  isOverdue() {
    return moment().startOf('day').diff(moment(this.props.v.date).startOf('day'), 'days') >= 1
  }

  renderFromDate() {
    if (this.isOverdue()) {
      return <strong>{this.diffToday(this.props.v.date)}</strong>
    } else {
      return this.diffToday(this.props.v.date)
    }
  }

  typeLabel() {
    let label
    if (this.props.v.type == 'hand_over') {
      label = _jed('Hand Over')
    } else if (this.props.v.type == 'take_back') {
      label = _jed('Take Back')
    } else {
      throw 'Invalid visit type'
    }
    return label
  }

  typeIconClass() {
    let c
    if (this.props.v.type == 'hand_over') {
      c = 'fa-mail-forward'
    } else if (this.props.v.type == 'take_back') {
      c = 'fa-mail-reply'
    } else {
      throw 'Invalid visit type'
    }
    return c
  }

  sendTakeBackReminder() {
    $.ajax({
      url: `/manage/${this.props.v.inventory_pool_id}/visits/${this.props.v.id}/remind`,
      method: 'POST',
      success: () => {
        this.setState({
          reminderSent: true
        })
      },
      error: (jqXHR, textStatus, errorThrown) => {
        Flash({
          type: 'error',
          message: errorThrown
        })
      }
    })
  }

  deleteHandOver() {
    $.ajax({
      url: `/manage/${this.props.v.inventory_pool_id}/visits/${this.props.v.id}`,
      method: 'POST',
      data: $.param({
        _method: 'delete'
      }),
      success: () => {
        this.setState({
          deleted: true
        })
      },
      error: (jqXHR, textStatus, errorThrown) => {
        Flash({
          type: 'error',
          message: errorThrown
        })
      }
    })
  }

  renderButton() {
    return (
      <div className="col1of5 line-col line-actions">
        {this.state.deleted && (
          <strong>
            {`${_jed('Deleted')} `}
            <i className="fa fa-trash" />
          </strong>
        )}
        {!this.state.deleted && (
          <div className="multibutton">
            <a
              className="button white text-ellipsis"
              href={`/manage/${this.props.v.inventory_pool_id}/users/${this.props.v.user_id}/${
                this.props.v.type
              }`}>
              <i className={`fa ${this.typeIconClass()}`} />
              {` ${this.typeLabel()}`}
            </a>
            <div className="dropdown-holder inline-block">
              <div className="button white dropdown-toggle">
                <div className="arrow down" />
              </div>
              {this.props.v.type == 'hand_over' && (
                <ul className="dropdown right">
                  <li onClick={this.deleteHandOver.bind(this)}>
                    <a className="dropdown-item red">
                      <i className="fa fa-trash" />
                      {` ${_jed('Delete')}`}
                    </a>
                  </li>
                </ul>
              )}
              {this.props.v.type == 'take_back' && (
                <ul className="dropdown right">
                  <li onClick={this.sendTakeBackReminder.bind(this)}>
                    <a className="dropdown-item">
                      <i className="fa fa-envelope" />
                      {` ${_jed('Send reminder')}`}
                    </a>
                  </li>
                </ul>
              )}
            </div>
          </div>
        )}
      </div>
    )
  }

  render() {
    return (
      <div data-id={this.props.v.id} key={this.props.v.id} className="line row focus-hover-thin">
        {this.isOverdue() && <div className="line-info red" />}
        <UserCell visit_id={this.props.v.id} {...this.props.v.user} />
        <div className="col1of5 line-col">{this.renderFromDate()}</div>
        <ReservationsCell
          visit_id={this.props.v.id}
          quantity={this.props.v.quantity}
          reservations={this.props.v.reservations}
        />
        <DaysRemindersCell
          isOverdue={this.isOverdue()}
          reminderSent={this.state.reminderSent}
          v={this.props.v}
        />
        {this.renderButton()}
      </div>
    )
  }
}

export default VisitRow
