module LeihsAdmin
  class InventoryController < AdminController

    def csv_export
      send_data InventoryPool.csv_export(nil, params),
                type: 'text/csv; charset=utf-8; header=present',
                disposition: "attachment; filename=#{_('Inventory')}.csv"
    end

    def excel_export
      send_data InventoryPool.excel_export(nil, params),
                type: 'application/xlsx',
                disposition: "filename=#{_('Inventory')}.xlsx"
    end

    def quick_csv_export
      objects = objects_for_quick_export
      header = header_for_export(objects)
      data = Export.csv_string(header, objects)

      send_data(
        data,
        type: 'text/csv; charset=utf-8; header=present',
        disposition: "attachment; filename=#{_('Inventory')}.csv"
      )
    end

    def quick_excel_export
      objects = objects_for_quick_export
      header = header_for_export(objects)
      data = Export.excel_string(
        header,
        objects,
        worksheet_name: _('Inventory')
      )

      send_data(
        data,
        type: 'application/xlsx',
        disposition: "filename=#{_('Inventory')}.xlsx"
      )
    end

    private

    def header_for_export(objects)
      objects.flat_map(&:keys).uniq
    end

    def objects_for_quick_export
      item_objects_for_quick_export.concat(
        option_objects_for_quick_export
      )
    end

    # rubocop:disable Metrics/MethodLength
    def item_objects_for_quick_export
      query = <<-SQL
        select
          items.created_at as created_at,
          items.updated_at as updated_at,
          items.inventory_code as inventory_code,
          models.product as product,
          models.version as version,
          models.manufacturer as manufacturer,
          models.description as description,
          models.technical_detail as technical_detail,
          models.internal_description as internal_description,
          models.hand_over_note as hand_over_note,
          models.type as type
          --	models.categories as categories, -- Categories
          --	models.accessories as accessories, -- Accessories
          --	models.compatibles as compatibles, -- Compatibles
          --	models.properties as properties -- Properties
        from
          items,
          models
        where
          items.model_id = models.id
      SQL
      result = ActiveRecord::Base.connection.exec_query(query).to_hash

      objects = result.map do |row|
        {
          _('Type') => if row['type'] == 'Model'
                         'Item'
                       elsif row['type'] == 'Software'
                         'License'
                       else
                         'Unknown'
                       end,
          _('Product') => row['product'],
          _('Version') => row['version'],
          _('Inventory Code') => row['inventory_code'],
          _('Created at') => row['created_at'],
          _('Updated at') => row['updated_at'],
          _('Manufacturer') => row['manufacturer'],
          _('Description') => row['description'],
          _('Technical Detail') => row['technical_detail'],
          _('Internal Description') => row['internal_description'],
          _('Important notes for hand over') => row['hand_over_note']
        }
      end
      objects
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def option_objects_for_quick_export
      query = <<-SQL
        select
          options.product as product,
          options.version as version,
          options.inventory_code as inventory_code,
          inventory_pools.name as inventory_pool_name,
          options.price as price
        from
          options,
          inventory_pools
        where
          options.inventory_pool_id = inventory_pools.id
      SQL
      result = ActiveRecord::Base.connection.exec_query(query).to_hash

      objects = result.map do |row|
        {
          _('Type') => 'Option',
          _('Product') => row['product'],
          _('Version') => row['version'],
          _('Inventory Code') => row['inventory_code'],
          _('Responsible department') => row['inventory_pool_name'],
          _('Initial Price') => row['price']
        }
      end
      objects
    end
    # rubocop:enable Metrics/MethodLength
  end
end
