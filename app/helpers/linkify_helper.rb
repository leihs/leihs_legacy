module LinkifyHelper

  def linkify_text(string)
    require 'rinku'
    tag_attrs = tag_options(target: :_blank, rel: :noopener, class: :autolinkified)
    Rinku.auto_link(string, :all, tag_attrs).html_safe
  end

end
