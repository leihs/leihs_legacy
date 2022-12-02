# NOTE we cannot hyphenated data attributes (yet), bacause autocomplete.coffee relies on underscored data attributes
Haml::Template.options[:hyphenate_data_attrs] = false
Haml::Template.options[:escape_filter_interpolations] = false
