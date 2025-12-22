const webpackMerge = require('webpack-merge')
const environment = require('./environment')
const customConfigs = require('./shared')

// Disable gzip compression
environment.plugins.delete('Compression')

module.exports = customConfigs.reduce(
  (a, b) => webpackMerge(a, b),
  environment.toWebpackConfig()
)
