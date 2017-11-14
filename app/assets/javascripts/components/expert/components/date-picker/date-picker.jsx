(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.DatePicker = React.createClass({
    propTypes: {
    },


    _monthTexts () {

      return [
        'Januar',
        'Februar',
        'März',
        'April',
        'Mai',
        'Juni',
        'Juli',
        'August',
        'September',
        'Oktober',
        'November',
        'Dezember'
      ]



    },

    _getMonthText () {
      return this._monthTexts()[this.state.month]
    },

    _getYear() {
      return this.state.year
    },

    getInitialState () {
      var date = new Date()
      return {
        year: date.getFullYear(),
        month: date.getMonth(),
        day: null
      }
    },

    _previous (event) {
      event.preventDefault()

      var date = new Date(this.state.year, this.state.month, 1)
      date.setMonth(date.getMonth() - 1)
      this.setState({year: date.getFullYear(), month: date.getMonth()})
    },


    _next (event) {
      event.preventDefault()

      var date = new Date(this.state.year, this.state.month, 1)
      date.setMonth(date.getMonth() + 1)
      this.setState({year: date.getFullYear(), month: date.getMonth()})
    },


    _daysInMonth () {
      return new Date(this.state.year, this.state.month + 1, 1 - 1).getDate()
    },

    _firstWeekday () {
      return new Date(this.state.year, this.state.month, 1).getDay()
    },


    _firstCol () {

      var weekday = this._firstWeekday()
      // Start with monday as 0
      if(weekday == 0) weekday += 7
      return weekday - 1
    },

    _select (event, index) {
      event.preventDefault()

      var year = this.state.year
      var month = this.state.month
      var day = index

      if(this.props.onSelect) {
        this.props.onSelect(day, month, year)
      }
    },


    componentDidMount() {
      document.addEventListener('mousedown', this._handleClickOutside);
    },

    componentWillUnmount() {
      document.removeEventListener('mousedown', this._handleClickOutside);
    },


    _handleClickOutside(event) {

      if (!this.reference.contains(event.target)) {
        if(this.props.onClose) {
          this.props.onClose()
        }

      }

    },


    _renderNumber (index) {


      var date = new Date()
      var currentYear = date.getFullYear()
      var currentMonth = date.getMonth()
      var currentDay = date.getDate() - 1

      var today = currentYear == this.state.year && currentMonth == this.state.month && currentDay == index


      var selected = false
      if(this.props.value) {
        var dayMonthYear = this.props.value
        selected = dayMonthYear.year == this.state.year && dayMonthYear.month == this.state.month && dayMonthYear.day == index
      }


      if(index >= 0 && index < this._daysInMonth()) {

        var todayStyle = null
        if(today) {
          todayStyle = {
            border: '1px solid grey',
            borderRadius: '5px'
          }
        }

        if(selected) {
          return (
            <td key={index} className='ui-datepicker-days-cell-over ui-datepicker-today'><a style={todayStyle} className='ui-state-default ui-state-highlight' href='#' onClick={(event) => this._select(event, index)}>{index + 1}</a></td>
          )

        } else {

          return (
            <td key={index} className=''><a style={todayStyle} className='ui-state-default' href='#' onClick={(event) => this._select(event, index)}>{index + 1}</a></td>
          )

        }




      } else {
        return (
          <td key={index} className='ui-datepicker-other-month ui-datepicker-unselectable ui-state-disabled'>&nbsp;</td>

        )

      }

    },


    _interval (n) {
      var arr = []
      for(var i = 0; i < n; i++) {
        arr.push(i)
      }
      return arr
    },

    _renderCols (row) {

      return this._interval(7).map((col) => {

        var index = row * 7 + col - this._firstCol()

        return this._renderNumber(index)
      })

    },

    _renderTable () {


      var rowCount = Math.ceil((this._firstCol() + this._daysInMonth()) / 7.0)

      return this._interval(rowCount).map((row) => {
        return (
          <tr key={row}>
            {this._renderCols(row)}

          </tr>
        )
      })

    },


    render () {
      const props = this.props

      return (

        <div ref={(ref) => this.reference = ref} id='ui-datepicker-div' className='ui-datepicker ui-widget ui-widget-content ui-helper-clearfix ui-corner-all' style={{display: 'block'}}>
           <div className='ui-datepicker-header ui-widget-header ui-helper-clearfix ui-corner-all'>
              <a className='ui-datepicker-prev ui-corner-all' title='<' onClick={this._previous}><span className='ui-icon ui-icon-circle-triangle-w'>&lt;</span></a><a className='ui-datepicker-next ui-corner-all' title='>'><span className='ui-icon ui-icon-circle-triangle-e' onClick={this._next}>&gt;</span></a>
              <div className='ui-datepicker-title'><span className='ui-datepicker-month'>{this._getMonthText()}</span>&nbsp;<span className='ui-datepicker-year'>{this._getYear()}</span></div>
           </div>
           <table className='ui-datepicker-calendar'>
              <thead>
                 <tr>
                    <th scope='col'><span title='Montag'>Mo</span></th>
                    <th scope='col'><span title='Dienstag'>Di</span></th>
                    <th scope='col'><span title='Mittwoch'>Mi</span></th>
                    <th scope='col'><span title='Donnerstag'>Do</span></th>
                    <th scope='col'><span title='Freitag'>Fr</span></th>
                    <th scope='col' className='ui-datepicker-week-end'><span title='Samstag'>Sa</span></th>
                    <th scope='col' className='ui-datepicker-week-end'><span title='Sonntag'>So</span></th>
                 </tr>
              </thead>
              <tbody>
                {this._renderTable()}



              </tbody>
           </table>
        </div>


      )
    }
  })
})()
