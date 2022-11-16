class Admin::InventoryController < Admin::ApplicationController

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
    item_objects_for_quick_export
    # .concat(
    #   option_objects_for_quick_export
    # )
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

  def item_objects_for_quick_export
    query = <<-SQL

        with
                prop_fields
        as (

                select
                        *
                from
                        fields

                where
            -- NOTE: We use the fiels which reference a property on the item.
                        substring((fields.data->>'attribute'::text) from 1 for 1) = '['
                        and jsonb_array_length((fields.data->>'attribute')::jsonb) = 2
                        and ((fields.data->>'attribute')::jsonb->>0) = 'properties'
        )

        select
          items.created_at as created_at,
          items.updated_at as updated_at,
          items.inventory_code as inventory_code,
          items.shelf as shelf,
          items.serial_number as serial_number,
          items.retired as retired,
          items.retired_reason as retired_reason,
          items.is_incomplete as is_incomplete,
          items.is_borrowable as is_borrowable,
          items.status_note as status_note,
          items.is_inventory_relevant as is_inventory_relevant,
          items.last_check as last_check,
          items.invoice_number as invoice_number,
          items.invoice_date as invoice_date,
          items.price as price,
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

          (select inventory_pools.name from inventory_pools where inventory_pools.id = items.owner_id) as owner_name,

          (select suppliers.name from suppliers where suppliers.id = items.supplier_id) as supplier_name,

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
          ))) as properties,



          (
            -- NOTE: prop_fields is defined "with ... as"
            -- We take the value in the item properties by the attribute defined in the fields.
            select
                to_json(array_agg(

                        json_build_object(
                                'label',
                                prop_fields.data->>'label',
                                'value',
                                items.properties->(
                                        (prop_fields.data->>'attribute')::jsonb->>1
                                )

                        )

                ))
            from
                 prop_fields
            where
                 items.properties->(
                    (prop_fields.data->>'attribute')::jsonb->>1
                  ) is not null
             and prop_fields.data->>'label' is not null

          ) as field_properties




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

      object = {
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
    _('Serial Number') => row['serial_number'],
    _('Retired') => row['retired'],
    _('Retired Reason') => row['retired_reason'],
    _('Complete') => (row['is_incomplete'] ? false : true),
    _('borrowable') => row['is_borrowable'],
    _('Status note') => row['status_note'],
    _('Relevant for inventory') => row['is_inventory_relevant'],
    _('Owner') => row['owner_name'],
    _('Last Checked') => row['last_check'],
    _('Invoice Number') => row['invoice_number'],
    _('Invoice Date') => row['invoice_date'],
    _('Supplier') => row['supplier_name'],
    _('Initial Price') => row['price'],
    # _('Additional Data') => \
    #   if row['field_properties']
    #     JSON.parse(row['field_properties']).map do |e|
    #       e['label'].to_s + ': ' + e['value'].to_s
    #     end.join('; ')
    #   end,
    _('Categories') => categories_to_string(row['categories']),
    _('Accessories') => accessories_to_string(row['accessories']),
    _('Compatibles') => compatibles_to_string(row['compatibles']),
    _('Properties') => properties_to_string(row['properties'])
      }

      if row['field_properties']
        JSON.parse(row['field_properties']).each do |p|
          object[p['label']] = p['value']
        end
      end

      object
  end
  objects
end

# def option_objects_for_quick_export
#   query = <<-SQL
#     select
#       options.product as product,
#       options.version as version,
#       options.inventory_code as inventory_code,
#       inventory_pools.name as inventory_pool_name,
#       options.price as price
#     from
#       options,
#       inventory_pools
#     where
#       options.inventory_pool_id = inventory_pools.id
#   SQL
#   result = ActiveRecord::Base.connection.exec_query(query).to_hash
#
#   objects = result.map do |row|
#     {
#       _('Type') => 'Option',
#       _('Product') => row['product'],
#       _('Version') => row['version'],
#       _('Inventory Code') => row['inventory_code'],
#       _('Created at') => nil,
#       _('Updated at') => nil,
#       _('Manufacturer') => row['manufacturer'],
#       _('Building') => nil,
#       _('Room') => nil,
#       _('Shelf') => nil,
#       _('Description') => nil,
#       _('Technical Detail') => nil,
#       _('Internal Description') => nil,
#       _('Important notes for hand over') => nil,
#       _('Responsible department') => row['inventory_pool_name'],
#       _('Initial Price') => row['price'],
#       _('Categories') => nil,
#       _('Accessories') => nil,
#       _('Compatibles') => nil,
#       _('Properties') => nil
#     }
#   end
#   objects
# end
end
