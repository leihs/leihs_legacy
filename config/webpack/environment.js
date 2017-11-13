// shared custom environment - *loader and plugins*

const webpack = require('webpack')
const webpackMerge = require('webpack-merge')
const { environment } = require('@rails/webpacker')
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer')
  .BundleAnalyzerPlugin

environment.plugins.set(
  'BundleAnalyzerPlugin',
  new BundleAnalyzerPlugin({
    analyzerMode: 'static',
    reportFilename: 'report.html',
    // Module sizes to show in report by default.
    // Should be one of `stat`, `parsed` or `gzip`.
    defaultSizes: 'parsed',
    // Automatically open report in default browser
    openAnalyzer: false,
    // If `true`, Webpack Stats JSON file will be generated in bundles output directory
    generateStatsFile: true,
    statsFilename: 'stats.json',
    // Log level. Can be 'info', 'warn', 'error' or 'silent'.
    logLevel: 'info'
  })
)

module.exports = environment
