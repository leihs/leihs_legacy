module ExpertFilter
  extend ActiveSupport::Concern

  include ExpertComparators

  included do

    private

    def reduce_items(items, field_id, filter_value, field_config)
      if field_id == 'attachments'
        throw 'Attachments are not allowed as filter.'
      end

      case field_config['type']
      when 'select'
        reduce_for_select(items, field_id, filter_value, field_config)
      when 'radio'
        reduce_for_radio(items, filter_value, field_config)
      when 'autocomplete'
        reduce_for_autocomplete(items, field_id, filter_value, field_config)
      when 'autocomplete-search'
        reduce_for_autocomplete_search(
          items, field_id, filter_value, field_config)
      when 'date'
        reduce_for_date(items, filter_value, field_config)
      when 'text'
        reduce_for_text(items, filter_value, field_config)
      when 'textarea'
        reduce_for_textarea(items, filter_value, field_config)
      else
        throw 'Unexpected field type: ' + field_config['type']
      end
    end

    def inventory_items(params, inventory_pool)
      items = Item.distinct

      items = items.by_owner_or_responsible(inventory_pool) if inventory_pool

      if params[:field_filters]
        field_filters = JSON.parse(URI::DEFAULT_PARSER.unescape(params[:field_filters]))

        if field_filters.length > 0

          filter_values = field_filters.map do |ff|
            [ff['id'], ff['value']]
          end.to_h

          field_data = field_filters.map do |ff|
            f = Field.find(ff['id'])
            [ff['id'], f.data]
          end.to_h

          field_data.each do |field_id, fd|

            items = reduce_items(items, field_id, filter_values[field_id], fd)
          end

        end
      end

      items
    end
  end
end
