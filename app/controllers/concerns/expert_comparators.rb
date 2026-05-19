module ExpertComparators
  extend ActiveSupport::Concern

  included do

    private

    def quoted_items_column(attribute)
      "items.#{ApplicationRecord.connection.quote_column_name(attribute)}"
    end

    def reduce_for_radio(items, filter_value, field_config)
      selection_id = filter_value['selection']

      if selection_id.nil?
        return items
      end

      generic_equal_value(items, selection_id, field_config)
    end

    def reduce_for_select(items, field_id, filter_value, field_config)
      value = filter_value['selection']

      if value.nil?
        return items
      end

      case field_id
      when 'retired'

        if value == true
          return items.where.not(retired: nil)
        else
          return items.where(retired: nil)
        end
      else
        generic_equal_value(items, value, field_config)
      end
    end

    def reduce_for_text(items, filter_value, field_config)
      if field_config['currency']

        from_string = filter_value['from']
        to_string = filter_value['to']

        if (from_string == '' || number?(from_string)) \
          && (to_string == '' || number?(to_string))
          from = \
            if number?(from_string)
              from_string.to_f
            end
          to = \
            if number?(to_string)
              to_string.to_f
            end

          if from.nil? && to.nil?
            return items
          end

          generic_between_value(items, from, to, field_config)
        else
          items.where('true = false')
        end
      else
        text = filter_value['text']

        if text == ''
          return items
        end

        generic_ilike(items, text, field_config)
      end
    end

    def reduce_for_textarea(items, filter_value, field_config)
      text = filter_value['text']

      if text == ''
        return items
      end

      generic_ilike(items, text, field_config)
    end

    def reduce_for_date(items, filter_value, field_config)
      date = filter_value['date']

      if date == ''
        return items
      end

      from_string = filter_value['from']
      to_string = filter_value['to']

      if (from_string == '' || date?(from_string)) \
        && (to_string == '' || date?(to_string))
        from = \
          if date?(from_string)
            Date.parse(from_string)
          end
        to = \
          if date?(to_string)
            Date.parse(to_string)
          end

        if from.nil? && to.nil?
          return items
        end

        generic_between_value(items, from, to, field_config)
      else
        items.where('true = false')
      end
    end

    def generic_between_value(items, from, to, field_config)
      attribute = field_config['attribute']

      if attribute.is_a?(String)
        column = quoted_items_column(attribute)
        result = items
        result = result.where("#{column} >= ?", from) if from
        result = result.where("#{column} <= ?", to) if to
        result
      elsif attribute.is_a?(Array)
        if attribute.length != 2
          throw 'Attribute length must be 2, but is: ' + attribute.to_s
        end
        if attribute[0] != 'properties'
          throw 'We expect properties, but is: ' + attribute.to_s
        end

        prop_key = attribute[1].to_s
        result = items
        result = result.where('items.properties ->> ? >= ?', prop_key, from) if from
        result = result.where('items.properties ->> ? <= ?', prop_key, to) if to
        result
      else
        throw 'Not supported attribute: ' + attribute.to_s
      end
    end

    def generic_equal_value(items, value, field_config)
      attribute = field_config['attribute']

      if attribute.is_a?(String)
        return items.where(attribute => value)
      elsif attribute.is_a?(Array)

        if attribute.length != 2
          throw 'Attribute length must be 2, but is: ' + attribute.to_s
        end
        if attribute[0] != 'properties'
          throw 'We expect properties, but is: ' + attribute.to_s
        end

        items.where('items.properties ->> ? = ?', attribute[1].to_s, value)
      else
        throw 'Not supported attribute: ' + attribute.to_s
      end
    end

    def generic_ilike(items, value, field_config)
      attribute = field_config['attribute']

      if attribute.is_a?(String)
        column = quoted_items_column(attribute)
        return items.where("#{column} ILIKE ?", "%#{value}%")
      elsif attribute.is_a?(Array)

        if attribute.length != 2
          throw 'Attribute length must be 2, but is: ' + attribute.to_s
        end
        if attribute[0] != 'properties'
          throw 'We expect properties, but is: ' + attribute.to_s
        end

        items.where(
          'items.properties ->> ? ILIKE ?',
          attribute[1].to_s,
          "%#{value}%")
      else
        throw 'Not supported attribute: ' + attribute.to_s
      end
    end

    def reduce_for_autocomplete(items, field_id, filter_value, field_config)
      selection_id = filter_value['id']

      if selection_id.nil?
        return items
      end

      case field_id
      when 'building_id'
        items.joins(:room).where(
          rooms: { building_id: selection_id })
      when 'inventory_pool_id'
        items.joins(:inventory_pool).where(
          inventory_pools: { id: selection_id })
      when 'owner_id'
        items.joins(:owner).where(
          inventory_pools: { id: selection_id })
      when 'supplier_id'
        items.joins(:supplier).where(
          suppliers: { id: selection_id })
      else
        generic_equal_value(items, selection_id, field_config)
      end
    end

    def reduce_for_autocomplete_search(items, field_id, filter_value, field_config)
      selection_id = filter_value['id']

      if selection_id.nil?
        return items
      end

      case field_id
      when 'model_id'
        items.joins(:model).where(models: { id: selection_id })
      else
        generic_equal_value(items, selection_id, field_config)
      end
    end

    def number?(string)
      true if Float(string) rescue false
    end

    def date?(string)
      true if Date.parse(string) rescue false
    end
  end
end
