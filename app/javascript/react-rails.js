// `react-rails`: Setup react_ujs as `ReactRailsUJS`
// and prepare a require context, using all components in directory
const componentRequireContext = require.context('components', true)
const ReactRailsUJS = require('react_ujs')
ReactRailsUJS.useContext(componentRequireContext)

export { ReactRailsUJS, componentRequireContext }
