module ManageInventoryMenu
  extend ActiveSupport::Concern

  included do
    def manage_inventory_menu
      {
          lending_manager:
            lending_manager?,
          csv_import_url:
            "/manage/#{current_inventory_pool.id}/inventory/csv_import",
          csv_export_url:
            manage_inventory_csv_export_path(current_inventory_pool),
          excel_export_url:
            manage_inventory_excel_export_path(current_inventory_pool),
          create_model_url:
            manage_new_model_path(current_inventory_pool),
          create_package_url:
            manage_new_item_path(
              current_inventory_pool,
              type: 'item',
              forPackage: true
            ),
          create_item_url:
            manage_new_item_path(current_inventory_pool),
          create_option_url:
            manage_new_option_path(current_inventory_pool),
          create_software_url:
            manage_new_model_path(current_inventory_pool, type: 'software'),
          create_license_url:
            manage_new_item_path(current_inventory_pool, type: 'license'),
         
        }
    end
  end
end
