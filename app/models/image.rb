class Image < ApplicationRecord

  belongs_to :target, polymorphic: true

  before_destroy do
    thumbnails = Image.where(parent_id: self.id, thumbnail: true)
    destroyed = thumbnails.destroy_all
    throw :abort if thumbnails.count != destroyed.count
  end

  validates_presence_of :content

  validates_presence_of :target, if: ->(image) { image.parent_id.nil? }

  validate do
    if size >= 8_000_000
      errors.add(:base, _('Uploaded file must be less than 8MB'))
    end
    unless content_type.match? %r{^image\/(png|gif|jpeg)}
      errors.add(:base, _('Unallowed content type'))
    end
  end

  validate do
    if not thumbnail \
      and Image.where(target_id: target_id, target_type: 'ModelGroup').exists?
      errors.add(:base, _('Category can have only one image.'))
    end
  end

end
