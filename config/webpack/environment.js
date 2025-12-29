// shared custom environment - *loader and plugins*

const { environment } = require('@rails/webpacker')

// Disable gzip and brotli compression
environment.plugins.delete('Compression')
environment.plugins.delete('Compression Brotli')

// Use relative paths in source maps instead of absolute local paths
environment.config.merge({
  output: {
    devtoolModuleFilenameTemplate: '[resource-path]',
    devtoolFallbackModuleFilenameTemplate: '[resource-path]?[hash]'
  }
})

module.exports = environment
