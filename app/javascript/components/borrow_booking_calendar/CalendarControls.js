import React from 'react'
import createReactClass from 'create-react-class'

const CalendarControls = createReactClass({
  displayName: 'CalendarControls',
  propTypes: {},

  getInitialState() {
    return {}
  },

  componentDidMount() {},

  render() {
    const month = i18n.months.full[this.props.firstDateOfCurrentMonth.month()]
    const year = this.props.firstDateOfCurrentMonth.year()

    return (
      <table className="fc-header" style={{ width: '100%' }}>
        <tbody>
          <tr>
            <td className="fc-header-left">
              <span className="fc-header-title">
                <h2>
                  {month} {year}
                </h2>
              </span>
            </td>
            <td className="fc-header-center" />
            <td className="fc-header-right">
              <span
                className="fc-button fc-button-today fc-state-default fc-corner-left fc-corner-right"
                unselectable="on">
                {_jed('today')}
              </span>
              <span className="fc-header-space" />
              <span
                onClick={this.props.previousMonthExists ? this.props.previousMonthCallback : null}
                className={
                  'fc-button fc-button-prev fc-state-default fc-corner-left fc-corner-right' +
                  (!this.props.previousMonthExists && ' fc-state-disabled')
                }
                unselectable="on">
                <span className="fc-text-arrow">‹</span>
              </span>
              <span className="fc-header-space" />
              <span
                onClick={this.props.nextMonthCallback}
                className="fc-button fc-button-next fc-state-default fc-corner-left fc-corner-right"
                unselectable="on">
                <span className="fc-text-arrow">›</span>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    )
  }
})

export default CalendarControls
