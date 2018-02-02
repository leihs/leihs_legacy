import React from 'react'
const DatePicker = window.DatePicker

class DatePickerPopup extends React.Component {
  render() {
    return (
      <div style={{ position: 'relative' }}>
        <div
          style={{
            position: 'absolute',
            zIndex: '1',
            display: 'block'
          }}
        >
          <DatePicker
            value={this.props.value}
            visible={true}
            onSelect={this.props.onSelect}
            onClose={this.props.onClose}
          />
        </div>
      </div>
    )
  }
}

export default DatePickerPopup
