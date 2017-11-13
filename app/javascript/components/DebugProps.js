import React from 'react'
import PropTypes from 'prop-types'
import cx from 'classnames'

function stringifyObj(obj) {
  obj = obj === null ? 'null' : obj === undefined ? 'undefined' : obj
  try {
    return JSON.stringify(obj)
  } catch (err) {
    return `Object: ${obj.toString()}; Error: ${err}`
  }
}

const DebugProps = props => (
  <div
    className={cx('react-compoent', { 'component-debug-props': true })}
    style={{
      border: '1px solid tomato',
      background: 'papayawhip',
      padding: '1.5rem',
      fontSize: '1.5rem'
    }}>
    <pre>{stringifyObj(props)}</pre>
  </div>
)

DebugProps.PropTypes = PropTypes.any

export default DebugProps
