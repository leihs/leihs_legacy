import React from 'react'
import createReactClass from 'create-react-class'
import CalendarDay from './CalendarDay'
import f from 'lodash'
// const inspect = window.Tools.inspect

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
    return !maxVisits || dateContext.visitsCount < maxVisits
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
            !(this._isVisit(date) && !this._poolHasStillCapacityFor(dateContext)) &&
            !(
              this._isVisit(date) &&
              this.props.isWithinAdvanceDaysPeriod(date, this.props.poolContext.workday)
            ) &&
            this.props.isPoolOpenOn(date, this.props.poolContext.workday)
          ) {
            availableQuantity = dateContext.availableQuantity
          }

          return (
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
              onSelectStartDate={this.props.onClickPopoverStartDateCallback}
              onSelectEndDate={this.props.onClickPopoverEndDateCallback}
            />
          )
        })}
      </tr>
    )
  }
})

export default CalendarRow
