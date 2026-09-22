// shared custom environment - *loader and plugins*

const webpack = require('webpack')
const { environment } = require('@rails/webpacker')

// Provide jQuery to the (old, jQuery-based) plugins we now bundle here
// (e.g. vendored fullcalendar 1.6.7 which references the global `jQuery`).
environment.plugins.append(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery'
  })
)

// Don't bundle moment's ~450KB of built-in locale files: the app only uses a
// custom "default" locale (see app/assets/javascripts/lib/i18n.coffee), and the
// old sprockets pipeline never bundled moment locales either.
environment.plugins.append(
  'IgnoreMomentLocales',
  new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/)
)

// Disable gzip and brotli compression (only if they exist)
try {
  environment.plugins.delete('Compression')
} catch (e) {}
try {
  environment.plugins.delete('Compression Brotli')
} catch (e) {}

// Use relative paths in source maps instead of absolute local paths
environment.config.merge({
  output: {
    devtoolModuleFilenameTemplate: '[resource-path]',
    devtoolFallbackModuleFilenameTemplate: '[resource-path]?[hash]'
  }
})

module.exports = environment
