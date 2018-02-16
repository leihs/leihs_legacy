import React from 'react'
import createReactClass from 'create-react-class'
import CalendarControls from './CalendarControls'
import CalendarContent from './CalendarContent'
import DateInput from './DateInput'
const inspect = window.Tools.inspect

const BorrowBookingCalendar = createReactClass({
  displayName: 'BorrowBookingCalendar',
  propTypes: {},

  getInitialState() {
    const todayDate = moment()
    const firstDateOfCurrentMonth = moment([todayDate.year(), todayDate.month(), 1])

    return {
      todayDate: todayDate,
      firstDateOfCurrentMonth: firstDateOfCurrentMonth,
      startDate: this.props.initialStartDate,
      endDate: this.props.initialEndDate,
      selectedDate: null,
      quantity: (this.props.initialQuantity || 1),
      isLoading: true,
      calendarData: [],
      poolContext: this.props.inventoryPools[0]
    }
  },

  componentDidMount() {
    this._fetchAndUpdateCalendarData(this._getLastDateInCalendarView(this.state.endDate))
  },

  _f: 'YYYY-MM-DD',

  _fetchAndUpdateCalendarData(toDate = null) {
    let fromDate
    if (_.isEmpty(this.state.calendarData)) {
      fromDate = this._getFirstDateInCalendarView(this.state.todayDate)
    } else {
      fromDate = _.last(this.state.calendarData)
        .date.clone()
        .add(1, 'day')
    }

    if (this.state.isLoading) {
      this._fetchAvailabilities(
        fromDate.format(this._f),
        toDate ? toDate.format(this._f) : this._getLastDateInCalendarView().format(this._f)
      ).done(data => {
        const newDates = _.map(data.list, avalObject => {
          return {
            date: moment(avalObject.d),
            availableQuantity: avalObject.quantity,
            visitsCount: avalObject.visits_count
          }
        })

        this.setState(prevState => {
          return {
            isLoading: false,
            calendarData: prevState.calendarData.concat(newDates)
          }
        })
      })
    }
  },

  _getFirstDateInCalendarView(date = null) {
    const firstDateOfMonth = date
      ? moment([date.year(), date.month()])
      : this.state.firstDateOfCurrentMonth

    let daysShift = firstDateOfMonth.day() - 1
    // in the default moment locale week starts on Sunday (index 0)
    if (daysShift == -1) {
      daysShift = 6
    }

    return firstDateOfMonth.clone().subtract(daysShift, 'day')
  },

  _getLastDateInCalendarView(date = null) {
    return this._getFirstDateInCalendarView(date)
      .clone()
      .add(41, 'day')
  },

  _dropUntil(arr, func) {
    if (_.isEmpty(arr) || func(_.head(arr))) {
      return arr
    } else {
      return this._dropUntil(_.rest(arr), func)
    }
  },

  _getDatesForCurrentMonthView() {
    const firstDate = this._getFirstDateInCalendarView()
    const arr1 = this._dropUntil(this.state.calendarData, el => {
      return el.date.isSame(firstDate)
    })
    return _.take(arr1, 42)
  },

  existingReservations() {
    // component used for editing existing reservations
    return (this.props.reservations.length != 0)
  },

  // TODO: a single callback should be given to this component.
  // right now the component is used in different contextes, where
  // different callback chains apply:
  // 1. CREATE NEW RESERVATIONS (from models index; involves ajax post)
  // 1.1 `createReservations` -> `finishCallback`
  // 2. UPDATE EXISTING RESERVATIONS (from customer order; involves ajax post)
  // 2.1 `createReservations` -> `finishCallback`
  // 2.2 `deleteReservations` -> `finishCallback`
  // 2.3 `changeTimeRange` -> `finishCallback`
  // 2.3 `changeTimeRange` -> `createReservations` -> `finishCallback`
  // 2.3 `changeTimeRange` -> `deleteReservations` -> `finishCallback`
  // 3. PREPARE RESERVATIONS FOR CUSTOMER ORDER (from template wizard; does not involve ajax post)
  // 3.3 `exclusiveCallback`
  getOnClickCallback() {
    if (this.props.exclusiveCallback) {
      return () => {
        this.props.exclusiveCallback({
          start_date: this.state.startDate.format(this._f),
          end_date: this.state.endDate.format(this._f),
          quantity: Number(this.state.quantity),
          inventory_pool_id: this.state.poolContext.inventory_pool.id
        })
      }
    } else {
      let callback
      if (this.hasQuantityIncreased()) {
        callback = this.createReservations
      } else if (this.hasQuantityDecreased()) {
        callback = this.deleteReservations
      } else {
        callback = this.props.finishCallback
      }

      if (this.existingReservations() && this.hasTimeRangeChanged()) {
        return () => this.changeTimeRange(callback)
      } else {
        return callback
      }
    }
  },

  changeTimeRange(successCallback) {
    $.ajax({
      url: '/borrow/reservations/change_time_range',
      method: 'POST',
      dataType: 'json',
      data: {
        line_ids: _.map(this.props.reservations, (r) => r.id),
        start_date: this.state.startDate.format(this._f),
        end_date: this.state.endDate.format(this._f),
        inventory_pool_id: this.state.poolContext.inventory_pool.id
      },
      success: successCallback,
      error: (xhr) => this.setState({serverError: xhr.statusText})
    })
  },

  deleteReservations() {
    const reservation_ids = _.map(this.props.reservations, (r) => r.id)
    $.ajax({
      url: '/borrow/reservations',
      method: 'DELETE',
      dataType: 'json',
      data: {
        line_ids: _.take(reservation_ids, (this.props.initialQuantity - this.state.quantity))
      },
      success: (data) => this.props.finishCallback(data),
      error: (xhr) => this.setState({serverError: xhr.statusText})
    })
  },

  createReservations() {
    $.ajax({
      url: '/borrow/reservations',
      method: 'POST',
      dataType: 'json',
      data: {
        start_date: this.state.startDate.format(this._f),
        end_date: this.state.endDate.format(this._f),
        model_id: this.props.model.id,
        inventory_pool_id: this.state.poolContext.inventory_pool.id,
        quantity: (this.state.quantity - this.props.initialQuantity)
      },
      success: (data) => this.props.finishCallback(data),
      error: (xhr) => {
        this.setState({serverError: xhr.statusText})
      }
    })
  },

  _fetchAvailabilities(startDate, endDate) {
    return $.ajax({
      url: '/borrow/booking_calendar_availability',
      method: 'GET',
      dataType: 'json',
      data: {
        start_date: startDate,
        end_date: endDate,
        model_id: this.props.model.id,
        inventory_pool_id: this.state.poolContext.inventory_pool.id,
        reservation_ids: _.map(this.props.reservations, (r) => r.id)
      }
    })
  },

  _switchMonth(direction) {
    this.setState(
      prevState => {
        let firstDateOfMonth
        switch (direction) {
          case 'forward':
            firstDateOfMonth = prevState.firstDateOfCurrentMonth.add(1, 'month')
            break
          case 'backward':
            firstDateOfMonth = prevState.firstDateOfCurrentMonth.subtract(1, 'month')
            break
          default:
            throw new Error('invalid switch month direction')
        }

        const isLoading = !this._isLoadedUptoDate(this._getLastDateInCalendarView())

        return {
          firstDateOfCurrentMonth: firstDateOfMonth,
          isLoading: isLoading
        }
      },
      this._fetchAndUpdateCalendarData // second callback argument to setState
    )
  },

  _isLoadedUptoDate(date) {
    return _.any(_.map(this.state.calendarData, el => el.date), d => d.isSame(date))
  },

  _changeStartDate(sd) {
    const ed = sd.isAfter(this.state.endDate) ? sd : this.state.endDate
    this.setState({ startDate: sd, endDate: ed })
  },

  changeSelectedDate(date) {
    this.setState({ selectedDate: date })
  },

  jumpToStartDate() {
    const firstDateOfJumpMonth = moment([this.state.startDate.year(), this.state.startDate.month(), 1])
    this.setState({firstDateOfCurrentMonth: firstDateOfJumpMonth})
  },

  jumpToEndDate() {
    const firstDateOfJumpMonth = moment([this.state.endDate.year(), this.state.endDate.month(), 1])
    this.setState({firstDateOfCurrentMonth: firstDateOfJumpMonth})
  },

  onClickPopoverStartDateCallback(sd) {
    const ed = this.state.endDate.isBefore(sd) ? sd : this.state.endDate
    this.setState({ startDate: sd, endDate: ed, selectedDate: null })
  },

  onClickPopoverEndDateCallback(ed) {
    const sd = this.state.startDate.isAfter(ed) ? ed : this.state.startDate
    this.setState({ endDate: ed, startDate: sd, selectedDate: null })
  },

  _changeEndDate(ed) {
    const sd = this.state.startDate.isAfter(ed) ? ed : this.state.startDate

    if (sd.isValid()) {
      const loadDate = this._getLastDateInCalendarView(ed)
      this.setState(
        {
          startDate: sd,
          endDate: ed,

          isLoading: !this._isLoadedUptoDate(loadDate)
        },
        () => this._fetchAndUpdateCalendarData(loadDate)
      )
    }
  },

  _changeQuantity(event) {
    this.setState({ quantity: event.target.value })
  },

  _changeInventoryPool(event) {
    let toDate
    if (this.state.endDate.month() > this.state.firstDateOfCurrentMonth.month()) {
      toDate = this._getLastDateInCalendarView(this.state.endDate)
    } else {
      toDate = this._getLastDateInCalendarView(this.state.firstDateOfCurrentMonth)
    }

    this.setState(
      {
        calendarData: [],
        isLoading: true,
        poolContext: _.find(
          this.props.inventoryPools,
          ip => ip.inventory_pool.id == event.target.value
        )
      },
      () => this._fetchAndUpdateCalendarData(toDate)
    )
  },

  _goToNextMonth() {
    this._switchMonth('forward')
  },

  _goToPreviousMonth() {
    this._switchMonth('backward')
  },

  _isAvailableForDateRange() {
    const range = _.select(
      this.state.calendarData,
      el =>
        el.date.isSameOrAfter(this.state.startDate) && el.date.isSameOrBefore(this.state.endDate)
    )
    const maxAval = _.min(_.map(range, el => el.availableQuantity))
    return this.state.quantity <= maxAval
  },

  _isPoolOpenOn(date, workday = this.state.poolContext.workday) {
    const daysOfWeek = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ]
    return workday[daysOfWeek[date.day()]]
  },

  _isWithinAdvanceDaysPeriod(date, workday = this.state.poolContext.workday) {
    return date.isBefore(
      this.state.todayDate.clone().add(workday.reservation_advance_days, 'day'),
      'day'
    )
  },

  _poolHasStillCapacityFor(date) {
    const dateContext = _.find(this.state.calendarData, el => el.date.isSame(date, 'day'))
    return (
      dateContext &&
      dateContext.visitsCount < this.state.poolContext.workday.max_visits[dateContext.date.day()]
    )
  },

  getHoliday(date) {
    return _.find(this.state.poolContext.holidays, holiday => {
      return (
        date.isSameOrAfter(moment(holiday.start_date), 'day') &&
        date.isSameOrBefore(moment(holiday.end_date), 'day')
      )
    })
  },

  getErrors() {
    let errors = []

    if (this.state.serverError) {
      errors.push(_jed(this.state.serverError))
    } else if (!this.state.startDate.isValid() || !this.state.endDate.isValid()) {
      errors.push('Invalid date')
    } else if (
      this.state.startDate.isBefore(this.state.todayDate, 'day') ||
      this.state.endDate.isBefore(this.state.todayDate, 'day')
    ) {
      errors.push('Start and end date cannot be in the past')
    } else if (this.state.startDate.isAfter(this.state.endDate, 'day')) {
      errors.push('Start date must be before end date')
    } else {
      if (!this._isAvailableForDateRange()) {
        errors.push('Item is not available in that time range')
      }
      if (!this._isPoolOpenOn(this.state.startDate) || this.getHoliday(this.state.startDate)) {
        errors.push('Inventory pool is closed on start date')
      }
      if (!this._isPoolOpenOn(this.state.endDate) || this.getHoliday(this.state.endDate)) {
        errors.push('Inventory pool is closed on end date')
      }
      if (this._isWithinAdvanceDaysPeriod(this.state.startDate)) {
        errors.push('No orders are possible on this start date')
      }
      if (!this._poolHasStillCapacityFor(this.state.startDate)) {
        errors.push('Booking is no longer possible on this start date')
      }
      if (!this._poolHasStillCapacityFor(this.state.endDate)) {
        errors.push('Booking is no longer possible on this end date')
      }
    }

    return errors
  },

  reloadCalendarContent() {
    this.setState({
      serverError: null,
      isLoading: true,
      calendarData: []
    }, this._fetchAndUpdateCalendarData)
  },

  _renderErrors(errors) {
    if (errors.length) {
      return (
        <div id="booking-calendar-errors">
          <div className="padding-horizontal-m padding-bottom-m">
            <div className="row emboss red text-align-center font-size-m padding-inset-s">
              <strong>
                {errors.push('') && errors.map(el => _jed(el)).join('. ')}
              </strong>
            </div>
          </div>
        </div>
      )
    } else {
      return null
    }
  },

  hasTimeRangeChanged() {
    return !(
      this.state.startDate.format(this._f) == this.props.initialStartDate.format(this._f) &&
      this.state.endDate.format(this._f) == this.props.initialEndDate.format(this._f)
    )
  },

  hasQuantityDecreased() {
    return this.state.quantity < this.props.initialQuantity
  },

  hasQuantityIncreased() {
    return this.state.quantity > this.props.initialQuantity
  },

  hasQuantityChanged() {
    return (this.hasQuantityDecreased() || this.hasQuantityIncreased())
  },

  renderAddButton(errors) {
    const isEnabled = errors.length == 0
    return (
      <button
        className="button green"
        id="submit-booking-calendar"
        onClick={this.getOnClickCallback()}
        disabled={!isEnabled}>
        {_jed('Add')}
      </button>
    )
  },

  renderContent() {
    let content
    if (this.state.isLoading) {
      content =
        <div>
          <div className="height-s" />
          <div className="loading-bg" />
          <div className="height-s" />
        </div>
    } else if (this.state.serverError) {
      const buttonStyle = {
        transform: 'scale(5)',
        color: '#30c91f',
        backgroundImage: 'none',
        backgroundColor: 'blueviolet',
        borderColor: '#ffda00',
        transform: 'skew(-0.06turn, 18deg) scale(5)'
      }
      content =
        <div>
          <div className="height-s" />
          <div style={{textAlign: 'center'}}>
            <button style={buttonStyle} className="button white large" onClick={this.reloadCalendarContent}>Reload</button>
          </div>
          <div className="height-s" />
        </div>
    } else {
      content =
        <CalendarContent
          startDate={this.state.startDate}
          endDate={this.state.endDate}
          quantity={this.state.quantity}
          dates={this._getDatesForCurrentMonthView()}
          currentMonth={this.state.firstDateOfCurrentMonth.month()}
          todayDate={this.state.todayDate}
          poolContext={this.state.poolContext}
          isPoolOpenOn={this._isPoolOpenOn}
          onClickPopoverStartDateCallback={this.onClickPopoverStartDateCallback}
          onClickPopoverEndDateCallback={this.onClickPopoverEndDateCallback}
          changeSelectedDate={this.changeSelectedDate}
          selectedDate={this.state.selectedDate}
          isWithinAdvanceDaysPeriod={this._isWithinAdvanceDaysPeriod}
          getHoliday={this.getHoliday}
        />
    }
    return content
  },

  render() {
    const errors = this.getErrors()

    return (
      <div>
        <div className="modal-header row">
          <div className="col3of5">
            <h2 className="headline-l">{_jed('Add to order')}</h2>
            <h3 className="headline-m light">
              {this.props.model.product} {this.props.model.version}
            </h3>
          </div>
          <div className="col2of5 text-align-right">
            <div className="modal-close">{_jed('Cancel')}</div>
            {this.renderAddButton(errors)}
          </div>
        </div>
        {!this.state.isLoading && this._renderErrors(errors)}
        <div className="modal-body" style={{ maxHeight: '895.4px' }}>
          <form className="padding-inset-m">
            <div className="" id="booking-calendar-controls">
              <div className="col5of8 float-right">
                <div className="row grey padding-bottom-xxs">
                  <div className="col1of2">
                    <div className="col1of2 padding-right-xs text-align-left">
                      <div className="row">
                        <span>{_jed('Start date')}</span>
                        <a
                          className="grey fa fa-eye position-absolute-right padding-right-xxs"
                          id="jump-to-start-date"
                          onClick={this.jumpToStartDate}
                        />
                      </div>
                    </div>
                    <div className="col1of2 padding-right-xs text-align-left">
                      <div className="row">
                        <span>{_jed('Start date')}</span>
                        <a
                          className="grey fa fa-eye position-absolute-right padding-right-xxs"
                          id="jump-to-end-date"
                          onClick={this.jumpToEndDate}
                        />
                      </div>
                    </div>
                  </div>
                  <div className="col1of2">
                    <div className="col2of8 text-align-left">{_jed('Quantity')}</div>
                    <div className="col6of8 padding-left-xs text-align-left">
                      {_jed('Inventory pool')}
                    </div>
                  </div>
                </div>
                <div className="row">
                  <div className="col1of2">
                    <div className="col1of2 padding-right-xs">
                      <DateInput
                        id="booking-calendar-start-date"
                        dateString={this.state.startDate.format(i18n.date.L)}
                        onChangeCallback={this._changeStartDate}
                      />
                    </div>
                    <div className="col1of2 padding-right-xs">
                      <DateInput
                        id="booking-calendar-end-date"
                        dateString={this.state.endDate.format(i18n.date.L)}
                        onChangeCallback={this._changeEndDate}
                      />
                    </div>
                  </div>
                  <div className="col1of2">
                    <div className="col2of8">
                      <input
                        autoComplete="off"
                        className="text-align-center"
                        id="booking-calendar-quantity"
                        type="number"
                        max={this.state.poolContext.total_borrowable}
                        defaultValue={this.state.quantity}
                        onChange={this._changeQuantity}
                      />
                    </div>
                    <div className="col6of8 padding-left-xs">
                      <select
                        autoComplete="off"
                        className="min-width-full text-ellipsis"
                        id="booking-calendar-inventory-pool"
                        value={this.state.poolContext.inventory_pool.id}
                        onChange={this._changeInventoryPool}>
                        {_.map(this.props.inventoryPools, (ipContext, key) => {
                          return (
                            <option
                              key={key}
                              data-id={ipContext.inventory_pool.id}
                              value={ipContext.inventory_pool.id}>
                              {ipContext.inventory_pool.name} (max. {ipContext.total_borrowable})
                            </option>
                          )
                        })}
                      </select>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div className="booking-calendar padding-top-xs fc fc-ltr" id="booking-calendar">
              <CalendarControls
                startDate={this.state.startDate}
                endDate={this.state.endDate}
                firstDateOfCurrentMonth={this.state.firstDateOfCurrentMonth}
                nextMonthCallback={this._goToNextMonth}
                previousMonthCallback={this._goToPreviousMonth}
                previousMonthExists={
                  this.state.firstDateOfCurrentMonth.month() != this.state.todayDate.month()
                }
              />
              {this.renderContent()}
            </div>
          </form>
        </div>
        <div className="modal-footer" />
      </div>
    )
  }
})

export default BorrowBookingCalendar
