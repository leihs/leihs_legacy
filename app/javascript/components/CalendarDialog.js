import React from 'react'
import createReactClass from 'create-react-class'
import BorrowBookingCalendar from './borrow_booking_calendar/BorrowBookingCalendar'

const CalendarDialog = createReactClass({
  displayName: 'CalendarDialog',
  propTypes: {},

  getInitialState() {
    return {}
  },

  componentDidMount() {
  },

  render() {
    return (
      <div>
        <BorrowBookingCalendar
          model={this.props.model}
          inventoryPools={this.props.inventoryPools}
          startDate={this.props.startDate}
          endDate={this.props.endDate}
          addButtonSuccessCallback={this.props.addButtonSuccessCallback}
        />
      </div>
    )
  }
})

export default CalendarDialog
