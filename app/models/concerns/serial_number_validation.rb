module SerialNumberValidation
  extend ActiveSupport::Concern

  included do
    validate :validates_serial_number, unless: :skip_serial_number_validation

    def unique_serial_number?
      not \
        Item
        .where.not(id: id)
        .where(
          "lower(replace(serial_number, ' ', '')) = lower(replace(?, ' ', ''))",
          serial_number
        )
        .exists?
    end

    attr_accessor :skip_serial_number_validation

    after_initialize do
      @skip_serial_number_validation = false
    end

    private

    def validates_serial_number
      if serial_number and \
          not skip_serial_number_validation and \
          not unique_serial_number?
        errors.add(:base, _('Same or similar serial number already exists.'))
      end
    end
  end
end
