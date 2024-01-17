class Attachment < ApplicationRecord

  belongs_to :model, inverse_of: :attachments
  belongs_to :item, inverse_of: :attachments

  validate do
    if size >= 100_000_000
      errors.add(:base, _('Uploaded file must be less than 100MB'))
    end
    unless content_type.match? %r{^(image\/(png|gif|jpeg)|application\/pdf)}
      errors.add(:base, _('Unallowed content type'))
    end
  end

  validate do
    unless model or item
      errors.add \
        :base,
        _('Attachment must be belong to model or item')
    end

    if model and item
      errors.add \
        :base,
        _('Attachment can\'t belong to model and item')
    end
  end

  def to_s
    filename
  end

end
