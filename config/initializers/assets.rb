# Be sure to restart your server when you modify this file.

if Rails.env.development?
  puts "run `npm ci` to make sure `node_modules` are up to date..."
  system('npm ci')
end

# Frontend libraries are installed with npm (see package.json) and served through
# Sprockets from node_modules. Libraries whose exact versions are not on npm live in
# vendor/assets (see the VENDOR.md files). This replaced the rails-assets.org gems.
Rails.application.config.assets.paths << Rails.root.join("node_modules")
# sprockets-rails precompiles every `application.js`/`application.css` it finds on any asset
# path by default. With node_modules on the path that would also match unrelated files
# (e.g. express/lib/application.js), so drop that catch-all; our entry points are listed
# explicitly below.
Rails.application.config.assets.precompile.reject! { |entry| entry.is_a?(Regexp) }

# npm packages ship `//# sourceMappingURL=...` comments next to their .map files. sprockets-rails
# would rewrite those into digested /assets/... URLs that we never precompile (404s in the browser
# console) and the extra lines change the bundles. We do not serve source maps for third-party
# libraries, so drop the comments before sprockets-rails (a postprocessor) gets to see them.
module StripNodeModulesSourceMappingUrl
  NODE_MODULES_DIR = Rails.root.join("node_modules").to_s.freeze
  SOURCE_MAPPING_URL_COMMENT = /^\/\/[#@] sourceMappingURL=.*\n?/

  def self.call(input)
    return unless input[:filename].to_s.start_with?(NODE_MODULES_DIR)
    { data: input[:data].gsub(SOURCE_MAPPING_URL_COMMENT, "") }
  end
end

Rails.application.config.assets.configure do |env|
  env.register_preprocessor "application/javascript", StripNodeModulesSourceMappingUrl
end

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += %w( application.js
                                                  admin.js
                                                  borrow.js
                                                  manage.js
                                                  admin.css
                                                  borrow.css
                                                  manage.css
                                                  print.css
                                                  i18n/locale/*
                                                  simile_timeline/*
                                                  timeline.css
                                                  upload.js
                                                  timecop/timecop-0.1.1.js
                                                )

# DOES NOT WORK: NoMethodError: undefined method `call' for JsrenderRails::Jsrender:Class
# Sprockets.register_mime_type 'text/jsr', extensions: ['.jsr']
# Sprockets.register_transformer 'text/jsr', 'application/javascript', JsrenderRails::Jsrender
# thus using deprecated way:
Rails.application.config.assets.configure do |env|
  env.register_engine '.jsr', JsrenderRails::Jsrender, silence_deprecation: true
end
