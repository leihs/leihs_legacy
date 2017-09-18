# NOTE we cannot hyphenated data attributes (yet), bacause autocomplete.coffee relies on underscored data attributes
Haml::Template.options[:hyphenate_data_attrs] = false

# force same whitespace behaviour in dev as in prod (!!!)
Haml::Template.options[:ugly] = true
