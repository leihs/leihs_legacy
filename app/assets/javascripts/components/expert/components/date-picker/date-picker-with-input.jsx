(() => {
  // NOTE: only for linter and clarity:
  /* global _ */
  /* global _jed */
  const React = window.React
  const ReactDOM = window.ReactDOM
  const Autocomplete = window.ReactAutocomplete
  React.findDOMNode = ReactDOM.findDOMNode // NOTE: autocomplete lib needs this

  window.DatePickerWithInput = React.createClass({
    propTypes: {
    },


    getInitialState () {

      return {
        visible: false,
        value: (this.props.value ? this.props.value : '')
      }
    },

    _onSelect (day, month, year) {

      var mom = moment().year(year).month(month).date(day + 1);

      var value = mom.format(i18n.date.L)
      this.setState({
        value: value,
        visible: false
      }, () => {

        if(this.props.onChange) {
          this.props.onChange(value)
        }

      })


    },


    _onChange (event) {
      var value = event.target.value
      this.setState({
        value: value
      })

      if(this.props.onChange) {
        this.props.onChange(value)
      }


    },

    _onClose () {
      this.setState({visible: false})
    },

    _renderPicker () {

      return (
        <div style={{position: 'relative'}}>
          <div style={{position: 'absolute', zIndex: '1', display: (this.state.visible ? 'block' : 'none')}}>
            <DatePicker value={CreateItemFieldSwitch._parseDayMonthYear(this.state.value)} visible={this.state.visible} onSelect={this._onSelect} onClose={this._onClose} />
          </div>
        </div>
      )

    },

    _onFocus () {
      this.setState({visible: true})
    },

    componentWillReceiveProps(nextProps) {

      if(nextProps.value != this.state.value) {
        this.setState({value: nextProps.value})
      }
    },


    render () {
      const props = this.props


      if(props.customRenderer) {

        return props.customRenderer({value: this.state.value, onChange: this._onChange, onFocus: this._onFocus, renderPicker: this._renderPicker})

      } else {

        return (
          // TODO Dummy wrapper. Remove when React supports arrays as return value.
          <span>
            <input placeholder={i18n.date.L} value={this.state.value} onChange={this._onChange} name={this.props.name} autoComplete='off' onFocus={this._onFocus} className='width-full hasDatepicker' type='text' />

            {this._renderPicker()}

          </span>


        )

      }


    }
  })
})()
