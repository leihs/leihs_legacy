class Image < ActiveRecord::Base
  audited

  belongs_to :target, polymorphic: true

  before_destroy do
    Image.where(parent_id: self.id, thumbnail: true).destroy_all
  end

  validates_presence_of :content

  validates_presence_of :target, if: ->(image) { image.parent_id.nil? }

  validate do
    if size < 4_000 and not thumbnail
      errors.add(:base, _('Uploaded file must be at least 4KB'))
    end
    if size >= 8_000_000
      errors.add(:base, _('Uploaded file must be less than 8MB'))
    end
    unless content_type.match %r{^image\/(png|gif|jpeg)}
      errors.add(:base, _('Unallowed content type'))
    end
  end

  validate do
    if not thumbnail \
      and Image.where(target_id: target_id, target_type: 'ModelGroup').exists?
      errors.add(:base, _('Category can have only one image.'))
    end
  end

  def label_for_audits
    filename
  end

end
