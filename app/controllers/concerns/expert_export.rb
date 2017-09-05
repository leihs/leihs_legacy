module ExpertExport
  extend ActiveSupport::Concern

  include ExpertFilter

  included do

    private

    def items_for_export(inventory_pool, params)
      items = inventory_items(params, inventory_pool)
      order_items_by_models(items)
    end

    def order_items_by_models(items)
      items.distinct.select('models.*, items.*').joins(:model)
        .reorder('models.product').order('models.version')
    end

    def header_for_export(objects_for_export)
      if objects_for_export.empty?
        [_('No entries found')]
      else
        objects_for_export.flat_map(&:keys).uniq
      end
    end

    def csv_export_expert(inventory_pool, params)
      objects = items_for_export(inventory_pool, params)
        .map(&:to_csv_array)
      header = header_for_export(objects)
      Export.csv_string(header, objects)
    end

    def excel_export_expert(inventory_pool, params)
      objects = items_for_export(inventory_pool, params)
        .map(&:to_csv_array)
      header = header_for_export(objects)
      Export.excel_string(header, objects, worksheet_name: _('Inventory'))
    end
  end
end
