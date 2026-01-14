import React from 'react'
import createReactClass from 'create-react-class'

const DateInput = createReactClass({
  displayName: 'DateInput ',
  propTypes: {},

  getInitialState() {
    return {
      dateString: this.props.dateString
    }
  },

  componentDidMount() {},

  componentWillReceiveProps(nextProps) {
    if (this.props.dateString != nextProps.dateString) {
      this.setState({ dateString: nextProps.dateString })
    }
  },

  onChangeCallback(event) {
    const val = event.target.value
    this.setState({ dateString: val }, () => {
      const date = moment(val, i18n.date.L, true)
      if (date.isValid()) {
        this.props.onChangeCallback(date)
      }
    })
  },

  render() {
    return (
      <input
        autoComplete="off"
        type="text"
        id={this.props.id}
        value={this.state.dateString}
        onChange={this.onChangeCallback}
      />
    )
  }
})

export default DateInput
