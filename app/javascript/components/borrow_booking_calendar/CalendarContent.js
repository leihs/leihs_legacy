import React from 'react'
import createReactClass from 'create-react-class'
import CalendarRow from './CalendarRow'

const CalendarContent = createReactClass({
  displayName: 'CalendarContent',
  propTypes: {},

  getInitialState() {
    return {}
  },

  componentDidMount() {
    // console.log( this.props.dates )
  },

  _splitDatesInRows() {
    var lists = _.groupBy(this.props.dates, function(element, index) {
      return Math.floor(index / 7)
    })
    return _.toArray(lists)
  },

  render() {
    return (
      <div className="fc-content" style={{ position: 'relative' }}>
        <div
          className="fc-view fc-view-month fc-grid"
          style={{ position: 'relative' }}
          unselectable="on">
          <div
            className="fc-event-container"
            style={{ position: 'absolute', zIndex: '8', top: '0', left: '0' }}
          />
          <table className="fc-border-separate" style={{ width: '100%' }} cellSpacing="0">
            <thead>
              <tr className="fc-first fc-last">
                <th
                  className="fc-day-header fc-mon fc-widget-header fc-first"
                  style={{ width: '102px' }}>
                  Mo
                </th>
                <th className="fc-day-header fc-tue fc-widget-header" style={{ width: '102px' }}>
                  Di
                </th>
                <th className="fc-day-header fc-wed fc-widget-header" style={{ width: '102px' }}>
                  Mi
                </th>
                <th className="fc-day-header fc-thu fc-widget-header" style={{ width: '102px' }}>
                  Do
                </th>
                <th className="fc-day-header fc-fri fc-widget-header" style={{ width: '102px' }}>
                  Fr
                </th>
                <th className="fc-day-header fc-sat fc-widget-header" style={{ width: '102px' }}>
                  Sa
                </th>
                <th className="fc-day-header fc-sun fc-widget-header fc-last">So</th>
              </tr>
            </thead>
            <tbody>
              {_.map(this._splitDatesInRows(), (row, key) => {
                return (
                  <CalendarRow
                    startDate={this.props.startDate}
                    endDate={this.props.endDate}
                    quantity={this.props.quantity}
                    todayDate={this.props.todayDate}
                    dates={row}
                    key={key}
                    last={key == 5}
                    currentMonth={this.props.currentMonth}
                    poolContext={this.props.poolContext}
                    isPoolOpenOn={this.props.isPoolOpenOn}
                    isWithinAdvanceDaysPeriod={this.props.isWithinAdvanceDaysPeriod}
                    onClickPopoverStartDateCallback={this.props.onClickPopoverStartDateCallback}
                    onClickPopoverEndDateCallback={this.props.onClickPopoverEndDateCallback}
                    changeSelectedDate={this.props.changeSelectedDate}
                    selectedDate={this.props.selectedDate}
                  />
                )
              })}
            </tbody>
          </table>
        </div>
      </div>
    )
  }
})

export default CalendarContent
