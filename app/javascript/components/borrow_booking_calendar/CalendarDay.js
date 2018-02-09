import React from 'react'
import createReactClass from 'create-react-class'

const CalendarDay = createReactClass({
  displayName: 'CalendarDay',
  propTypes: {
  },

  getInitialState () {
    return {
    }
  },

  componentDidMount () {
  },

  render () {
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
      <td onClick={this.props.onClick} className={klass} data-date={this.props.date.format('YYYY-MM-DD')}>
        <div style={{minHeight: '85px'}}>
          <div className='fc-day-number'>{this.props.date.date()}</div>
          <div className='fc-day-content'>
            <span className='holidays'>
              <span className='entry' title={this.props.holiday}>{this.props.holiday}</span>
            </span>
            <div style={{position: 'relative', height: '0px'}}>{this.props.availableQuantity}</div>
            <span className='other_month'>
              {this.props.isFromOtherMonth && i18n.months.trunc [ this.props.date.month() ]}
            </span>
          </div>
        </div>
      </td>
    )
  }
})

export default CalendarDay
