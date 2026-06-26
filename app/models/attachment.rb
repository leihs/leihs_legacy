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

  def self.cleanup_stale!
    two_years_ago = 2.years.ago.to_date

    where(item_id: nil).where(<<~SQL, two_years_ago).delete_all
      model_id IN (
        SELECT m.id FROM models m
        WHERE EXISTS (SELECT 1 FROM items WHERE items.model_id = m.id)
          AND NOT EXISTS (SELECT 1 FROM items WHERE items.model_id = m.id AND items.retired IS NULL)
          AND NOT EXISTS (
            SELECT 1 FROM reservations r
            JOIN items i ON i.id = r.item_id
            WHERE i.model_id = m.id AND r.end_date > ?
          )
      )
    SQL

    where(model_id: nil).where(<<~SQL, two_years_ago).delete_all
      item_id IN (
        SELECT i.id FROM items i
        WHERE i.retired IS NOT NULL
          AND NOT EXISTS (
            SELECT 1 FROM reservations r
            WHERE r.item_id = i.id AND r.end_date > ?
          )
      )
    SQL
  end

  def to_s
    filename
  end

end
