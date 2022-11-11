# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
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
