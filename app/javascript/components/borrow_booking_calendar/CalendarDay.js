/* global i18n, _jed */
import React from 'react'
import createReactClass from 'create-react-class'

const CalendarDay = createReactClass({
  displayName: 'CalendarDay',
  propTypes: {},

  getInitialState() {
    return {}
  },

  componentDidMount() {},

  render() {
    var klass = 'fc-day fc-widget-content'
    if (this.props.last) {
      klass += ' fc-last'
    }
    if (this.props.isFromOtherMonth) {
      klass += ' fc-other-month'
    }
    if (this.props.isAvailable) {
      klass += ' available'
    } else {
      klass += ' unavailable'
    }
    if (this.props.isSelected) {
      klass += ' selected'
    }

    return (
      <td
        onClick={this.props.onClick}
        className={klass}
        data-date={this.props.date.format('YYYY-MM-DD')}>
        <div style={{ minHeight: '85px' }}>
          <div className="fc-day-number">{this.props.date.date()}</div>
          <div className="fc-day-content">
            <span className="holidays">
              <span className="entry" title={this.props.holiday}>
                {this.props.holiday}
              </span>
            </span>
            <div style={{ position: 'relative', height: '0px' }}>
              {this.props.availableQuantity}
            </div>
            <span className="other_month">
              {this.props.isFromOtherMonth && i18n.months.trunc[this.props.date.month()]}
            </span>
          </div>
        </div>
        <div
          className="show-only-when-hovered"
          style={{
            height: '85px',
            width: '100%',
            position: 'absolute',
            top: 0,
            background: 'rgba(255, 255, 255, 0.6)',
            padding: '9px 6px',
            border: 'transparent'
          }}>
          <a
            onClick={() => this.props.onSelectStartDate(this.props.date)}
            className="col1of1 button white text-ellipsis"
            style={{ marginBottom: '6px' }}
            title={_jed('Start date')}>
            {_jed('Start date')}
          </a>
          <div className="col1of9" />
          <a
            onClick={() => this.props.onSelectEndDate(this.props.date)}
            className="col1of1 button white text-ellipsis"
            title={_jed('End date')}>
            {_jed('End date')}
          </a>
        </div>
      </td>
    )
  }
})

export default CalendarDay
