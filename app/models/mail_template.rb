class MailTemplate < ApplicationRecord

  self.inheritance_column = nil

  belongs_to :inventory_pool # NOTE when null, then is system-wide
  belongs_to :language, primary_key: :locale, foreign_key: :language_locale

  validates_uniqueness_of :name, scope: [:inventory_pool_id, :language_locale, :format]
  validate :syntax_validation

  after_save do
    destroy if body.blank?
  end

  def self.liquid_variables_for_order(order, comment = nil)
    { user: { name: order.target_user.name },
      inventory_pool: { name: order.inventory_pool.name,
                        contact: order.inventory_pool.contact,
                        workdays: order.inventory_pool.workday.render_for_email_template,
                        holidays: order.inventory_pool.holidays.render_for_email_template,
                        description: order.inventory_pool.description,
                        email_signature: order.inventory_pool.email_signature },
      email_signature: Setting.first.email_signature,
      reservations: order.reservations.map do |l|
       { quantity: l.quantity,
         model_name: l.model.name,
         start_date: l.start_date,
         end_date: l.end_date }
      end,
      comment: comment,
      purpose: order.purpose,
      order_url: order.edit_url
    }.deep_stringify_keys
  end

  def self.liquid_variables_for_user(user, inventory_pool, reservations)
    { user: { name: user.name },
      inventory_pool: { name: inventory_pool.name,
                        contact: inventory_pool.contact,
                        workdays: inventory_pool.workday.render_for_email_template,
                        holidays: inventory_pool.holidays.render_for_email_template,
                        description: inventory_pool.description,
                        email_signature: inventory_pool.email_signature },
      email_signature: Setting.first.email_signature,
      reservations: reservations.map do |l|
       { quantity: l.quantity,
         model_name: l.model.name,
         item_inventory_code: l.item.inventory_code,
         start_date: l.start_date,
         end_date: l.end_date }
      end,
      quantity: reservations.to_a.sum(&:quantity),
      due_date: reservations.first.end_date
    }.deep_stringify_keys
  end

  def self.get_template(inventory_pool, name, language)
    l = language || Language.default_language
    MailTemplate.find_by!(inventory_pool_id: inventory_pool.id,
                          name: name,
                          language: l,
                          format: 'text')
  end

  private

  def syntax_validation
    begin
      Liquid::Template.parse(body, error_mode: :strict)
    rescue => e
      errors.add :base, e.to_s
    end
  end

end
