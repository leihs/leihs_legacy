import React from 'react'
import ReactDOM from 'react-dom'
import createReactClass from 'create-react-class'
import CalendarDay from './CalendarDay'
import { Popover, OverlayTrigger } from 'react-bootstrap'
import f from 'lodash'
const inspect = window.Tools.inspect

const CalendarRow = createReactClass({
  displayName: 'CalendarRow',
  propTypes: {},

  getInitialState() {
    return {
      openDay: null
    }
  },

  componentDidMount() {},

  _isVisit(date) {
    return date.isSame(this.props.startDate, 'day') || date.isSame(this.props.endDate, 'day')
  },

  _poolHasStillCapacityFor(dateContext) {
    const maxVisits = this.props.poolContext.workday.max_visits[dateContext.date.day()]
    return (!maxVisits || dateContext.visitsCount < maxVisits)
  },

  onClickCallback(date) {
    if (date.isSameOrAfter(this.props.todayDate, 'day')) {
      this.props.changeSelectedDate(date)
    } else {
      this.props.changeSelectedDate(null)
    }
  },

  render() {
    var klass = 'fc-week'
    if (this.props.last) {
      klass += ' fc-last'
    }
    if (this.props.first) {
      klass += ' fc-first'
    }
    return (
      <tr className={klass}>
        {_.map(this.props.dates, (dateContext, key) => {
          const date = dateContext.date
          const holiday = this.props.getHoliday(date)

          const isAvailable =
            date.isSameOrAfter(this.props.todayDate, 'day') &&
            !(
              this._isVisit(date) &&
              (holiday ||
                this.props.isWithinAdvanceDaysPeriod(date, this.props.poolContext.workday) ||
                !this.props.isPoolOpenOn(date, this.props.poolContext.workday) ||
                !this._poolHasStillCapacityFor(dateContext))
            ) &&
            this.props.quantity <= dateContext.availableQuantity

          const isSelected =
            date.isSameOrAfter(this.props.startDate, 'day') &&
            date.isSameOrBefore(this.props.endDate, 'day')

          let availableQuantity
          if (
            date.isSameOrAfter(this.props.todayDate, 'day') &&
            !holiday &&
            !(
              this._isVisit(date) &&
              !this._poolHasStillCapacityFor(dateContext)
            ) &&
            !(
              this._isVisit(date) &&
              this.props.isWithinAdvanceDaysPeriod(date, this.props.poolContext.workday)
            ) &&
            this.props.isPoolOpenOn(date, this.props.poolContext.workday)
          ) {
            availableQuantity = dateContext.availableQuantity
          }

          const popover =
            <Popover id={`popover-${date.toString()}`} style={{ width: '220px' }}>
              <div className="row">
                <a
                  className="col4of9 button small white"
                  onClick={this.props.onClickPopoverStartDateCallback.bind(null, date)}
                  style={{ fontSize: '0.85em' }}>
                  {_jed('Start date')}
                </a>
                <div className="col1of9" />
                <a
                  className="col4of9 button small white"
                  onClick={this.props.onClickPopoverEndDateCallback.bind(null, date)}
                  style={{ fontSize: '0.85em' }}>
                  {_jed('End date')}
                </a>
              </div>
            </Popover>

          return (
            <OverlayTrigger
              key={`overlay-${date.toString()}`}
              id={`overlay-${date.toString()}`}
              rootClose
              delayShow={0}
              delayHide={0}
              placement="top"
              trigger="click"
              overlay={popover}>
              <CalendarDay
                date={date}
                availableQuantity={availableQuantity}
                isAvailable={isAvailable}
                isSelected={isSelected}
                key={date.toString()}
                last={key == 6}
                month={date.month()}
                isFromOtherMonth={this.props.currentMonth != date.month()}
                holiday={holiday && holiday.name}
                onClick={() => this.onClickCallback(date)}
                ref={`popovertarget-${date.toString()}`}
              />
            </OverlayTrigger>
          )
        })}
      </tr>
    )
  }
})

export default CalendarRow
