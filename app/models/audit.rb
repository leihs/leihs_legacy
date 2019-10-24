class Audit < Audited::Audit
  include Concerns::ScopeIfPresence

  def self.filter(start_date: nil,
                  end_date: nil,
                  auditable_id: nil,
                  auditable_type: nil,
                  search_term: nil,
                  user_id: nil)
     Audit
       .scope_if_presence(auditable_type) do |audits, auditable_type|
         audits.where(auditable_type: auditable_type)
       end
       .scope_if_presence(auditable_id) do |audits, auditable_id|
         audits.where(auditable_id: auditable_id)
       end
       .scope_if_presence(start_date) do |audits, start_date|
         audits.filter_since_start_date(start_date)
       end
       .scope_if_presence(end_date) do |audits, end_date|
         audits.filter_before_end_date(end_date)
       end
       .scope_if_presence(search_term) do |audits, search_term|
         audits.filter_by_term(search_term)
       end
       .scope_if_presence(user_id) do |audits, user_id|
         audits.where(user_id: user_id)
       end
  end

  def self.filter_since_start_date(start_date)
    where('audits.created_at::date >= ?', start_date)
  end

  def self.filter_before_end_date(end_date)
    where('audits.created_at::date <= ?', end_date)
  end

  def self.filter_by_term(term)
    where(<<-SQL, ilike_term: "%#{term}%")
      audited_changes ILIKE :ilike_term
      OR EXISTS
        (SELECT 1
         FROM users
         WHERE users.id = audits.user_id
           AND (users.firstname || ' ' || users.lastname) ILIKE :ilike_term)
      OR EXISTS
        (SELECT 1
         FROM users
         WHERE users.id = audits.auditable_id
           AND users.lastname ILIKE :ilike_term)
      OR EXISTS
        (SELECT 1
         FROM items
         WHERE items.id = audits.auditable_id
           AND items.inventory_code ILIKE :ilike_term)
      OR EXISTS
        (SELECT 1
         FROM models
         WHERE models.id = audits.auditable_id
           AND models.product ILIKE :ilike_term)
      OR EXISTS
        (SELECT 1
         FROM reservations
         JOIN items ON items.id = reservations.item_id
         WHERE reservations.id = audits.auditable_id
           AND items.inventory_code ILIKE :ilike_term)
    SQL
  end
end
