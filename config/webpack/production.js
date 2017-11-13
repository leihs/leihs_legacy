const webpackMerge = require('webpack-merge')
const environment = require('./environment')
const customConfigs = require('./shared')

module.exports = customConfigs.reduce(
  (a, b) => webpackMerge(a, b),
  environment.toWebpackConfig()
)
