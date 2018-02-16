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
          initialStartDate={this.props.initialStartDate}
          initialEndDate={this.props.initialEndDate}
          initialQuantity={this.props.initialQuantity || 0}
          reservations={this.props.reservations || []}
          finishCallback={this.props.finishCallback}
          exclusiveCallback={this.props.exclusiveCallback}
        />
      </div>
    )
  }
})

export default CalendarDialog
