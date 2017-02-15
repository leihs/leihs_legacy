module Procurement
  class Image < ActiveRecord::Base
    belongs_to :main_category

    validate do
      unless content_type.match %r{^image\/(png|gif|jpeg)}
        errors.add(:base, _('Unallowed image content type'))
      end
    end

    def thumbnail
      Image.find_by(parent_id: id)
    end
  end
end
