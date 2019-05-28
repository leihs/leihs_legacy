class Setting < ApplicationRecord
  audited

  SERVICE_RESTART_ATTRIBUTES =
    [:external_base_url,
     :ldap_config,
     :local_currency_string,
     :mail_delivery_method,
     :time_zone,
     *attribute_names.select { |attr| attr.start_with?('smtp') }].freeze

  validates_presence_of :local_currency_string,
                        :email_signature,
                        :default_email
  validates_presence_of :disable_borrow_section_message,
                        if: :disable_borrow_section?
  validates_presence_of :disable_manage_section_message,
                        if: :disable_manage_section?

  # validates_numericality_of :smtp_port, greater_than: 0
  # FIXME migration not running
  # validates_numericality_of :timeout_minutes, greater_than: 0

  validates_format_of :default_email,
                      with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  validates_each :documentation_link, allow_blank: true do |record, attr, value|
    begin
      uri = URI.parse value
    rescue
      next record.errors.add attr, _('is not a valid URL')
    end
    unless uri.is_a?(URI::HTTP) or uri.is_a?(URI::HTTPS)
      record.errors.add attr, _('is not a HTTP(S) URL')
    end
  end

  before_create do
    raise 'Setting is a singleton' if Setting.count > 0
  end

  def label_for_audits
    'Settings'
  end

end
