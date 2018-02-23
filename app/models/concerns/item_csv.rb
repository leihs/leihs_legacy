module Concerns
  module ItemCsv
    # Generates an array suitable for outputting a line of CSV using CSV
    def to_csv_array(options = { global: false })
      model_manufacturer = get_model_manufacturer
      categories = get_categories options[:global]

      # retired = if options[:global] and self.retired? then
      #             "X"
      #           else
      #             self.retired
      #           end
      #
      # if self.parent
      #   part_of_package = "#{self.parent.id} #{self.parent.model.name}"
      # else
      #   part_of_package = "NONE"
      # end
      #
      # if ref = self.properties[:reference]
      #   case ref
      #     when "invoice"
      #       invoice = "X"
      #     when "investment"
      #       investment = "X"
      #   end
      # end

      # Using #{} notation to catch nils gracefully and silently
      # FIXME: using model.try because database inconsistency
      h1 = {
        _('Created at') => "#{self.created_at}",
        _('Updated at') => "#{self.updated_at}",
        _('Product') => model.try(:product),
        _('Version') => model.try(:version),
        _('Manufacturer') => model_manufacturer
      }
      if type == 'Item'
        h1.merge!(
          # FIXME: using model.try because database inconsistency
          _('Description') => model.try(:description)
        )
      end
      h1.merge!(
        # FIXME: using model.try because database inconsistency
        case model.try(:type)
        when 'Software'
          _('Software Information')
        else
          _('Technical Details')
        end => model.try(:technical_detail)
      )
      if type == 'Item'
        # FIXME: using model.try because database inconsistency
        h1.merge!(
          _('Internal Description') => model.try(:internal_description),
          _('Important notes for hand over') => model.try(:hand_over_note),
          _('Categories') => categories.join('; '),
          _('Accessories') => \
            (model ? model.accessories.map(&:to_s) : []).join('; '),
          _('Compatibles') => \
            (model ? model.compatibles.map(&:to_s) : []).join('; '),
          _('Properties') => \
            (model ? model.properties.map(&:to_s) : []).join('; '),
        # part_of_package: part_of_package,
        # needs_permission: "#{self.needs_permission}",
        # responsible: "#{self.responsible}",
        # location: "#{self.location}",
        # invoice: invoice,
        # investment: investment
        )
      end

      fields = get_fields

      h2 = {}
      fields.each do |field|
        next if %w(attachments building_id room_id shelf).include? field.id
        h2[_(field.data['label'])] = field.value(self)
      end
      h1.merge! h2

      h1.merge!(
        _('Building') => room.building.name,
        _('Room') => room.name,
        _('Shelf') => shelf,
        "#{_('Borrower')} #{_('First name')}" => current_borrower.try(:firstname),
        "#{_('Borrower')} #{_('Last name')}" => current_borrower.try(:lastname),
        "#{_('Borrower')} #{_('Personal ID')}" => \
          current_borrower.try(:extended_info).try(:fetch, 'id', nil) \
            || current_borrower.try(:org_id),
        "#{_('Borrowed until')}" => "#{current_reservation.try(:end_date)}"
      )
      h1
    end
  end
end
