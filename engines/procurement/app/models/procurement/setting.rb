module Procurement
  class Setting < ApplicationRecord

    KEYS = %w(contact_url inspection_comments)

    def self.all_as_hash
      # NOTE: workaround when settings dont exist at all (tests)
      empty_attrs = Procurement::Setting.new.as_json
      attrs = Procurement::Setting.first.as_json
      empty_attrs.merge(attrs || {}).slice(*KEYS)
    end

  end
end
