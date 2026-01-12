// shared custom environment - *loader and plugins*

const { environment } = require('@rails/webpacker')

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
