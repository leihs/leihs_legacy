module LeihsAdmin
  # rubocop:disable Metrics/ClassLength
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

    def categories_to_string(from_db)
      JSON.parse(from_db).join('; ')
    end

    def accessories_to_string(from_db)
      JSON.parse(from_db).join('; ')
    end

    def compatibles_to_string(from_db)
      json = JSON.parse(from_db)
      json.map do |e|
        if e['version']
          e['product'].to_s + ' ' + e['version'].to_s
        else
          e['product'].to_s
        end
      end.join('; ')
    end

    def properties_to_string(from_db)
      json = JSON.parse(from_db)
      json.map do |e|
        e['key'].to_s + ': ' + e['value'].to_s
      end.join('; ')
    end

    # rubocop:disable Metrics/MethodLength
    def item_objects_for_quick_export
      query = <<-SQL
        select
          items.created_at as created_at,
          items.updated_at as updated_at,
          items.inventory_code as inventory_code,
          items.shelf as shelf,
          models.product as product,
          models.version as version,
          models.manufacturer as manufacturer,
          models.description as description,
          models.technical_detail as technical_detail,
          models.internal_description as internal_description,
          models.hand_over_note as hand_over_note,
          models.type as type,
          rooms.name as room_name,
          buildings.name as building_name,

          array_to_json(array((
            select
              model_groups.name
            from
              model_groups,
              model_links
            where
              model_groups.type = 'Category'
              and model_links.model_id = models.id
              and model_groups.id = model_links.model_group_id
          ))) as categories,

          array_to_json(array((
            select
              accessories.name
            from
              accessories
            where
              accessories.model_id = models.id
          ))) as accessories,

          array_to_json(array((
            select
              json_build_object(
                'product', compatible_models.product,
                'version', compatible_models.version
              )
            from
              models_compatibles,
              models as compatible_models
            where
              models_compatibles.model_id = models.id
              and compatible_models.id = models_compatibles.compatible_id
          ))) as compatibles,

          array_to_json(array((
            select
              json_build_object(
                'key', properties.key,
                'value', properties.value
              )
            from
              properties
            where
              properties.model_id = models.id
          ))) as properties

        from
          items,
          models,
          rooms,
          buildings
        where
          items.model_id = models.id
          and rooms.id = items.room_id
          and buildings.id = rooms.building_id
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
          _('Building') => row['building_name'],
          _('Room') => row['room_name'],
          _('Shelf') => row['shelf'],
          _('Description') => row['description'],
          _('Technical Detail') => row['technical_detail'],
          _('Internal Description') => row['internal_description'],
          _('Important notes for hand over') => row['hand_over_note'],
          _('Responsible department') => nil,
          _('Initial Price') => nil,
          _('Categories') => categories_to_string(row['categories']),
          _('Accessories') => accessories_to_string(row['accessories']),
          _('Compatibles') => compatibles_to_string(row['compatibles']),
          _('Properties') => properties_to_string(row['properties'])
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
          _('Created at') => nil,
          _('Updated at') => nil,
          _('Manufacturer') => row['manufacturer'],
          _('Building') => nil,
          _('Room') => nil,
          _('Shelf') => nil,
          _('Description') => nil,
          _('Technical Detail') => nil,
          _('Internal Description') => nil,
          _('Important notes for hand over') => nil,
          _('Responsible department') => row['inventory_pool_name'],
          _('Initial Price') => row['price'],
          _('Categories') => nil,
          _('Accessories') => nil,
          _('Compatibles') => nil,
          _('Properties') => nil
        }
      end
      objects
    end
    # rubocop:enable Metrics/MethodLength
  end
  # rubocop:enable Metrics/ClassLength
end
