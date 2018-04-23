class Manage::InventoryController < Manage::ApplicationController

  private

  # NOTE overriding super controller
  def required_manager_role
    open_actions = [:index, :csv_export, :excel_export]
    if open_actions.include?(action_name.to_sym)
      require_role :group_manager, current_inventory_pool
    else
      super
    end
  end

  public

  def index
    respond_to do |format|
      format.html do

        session[:params] = nil if params[:filters] == 'reset'

        items = Item.filter(params.clone.merge(paginate: 'false', all: 'true'),
                            current_inventory_pool)
        responsibles = \
          InventoryPool
            .distinct
            .joins(:items)
            .where("items.id IN (#{items.select('items.id').to_sql})")
            .where(
              InventoryPool
                .arel_table[:id]
                .eq(Item.arel_table[:inventory_pool_id])
            )

        @props = {
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
          create_item_url:
            manage_new_item_path(current_inventory_pool),
          create_option_url:
            manage_new_option_path(current_inventory_pool),
          create_software_url:
            manage_new_model_path(current_inventory_pool, type: 'software'),
          create_license_url:
            manage_new_item_path(current_inventory_pool, type: 'license'),
          responsibles:
            responsibles
        }
      end
      format.json do
        session[:params] = params.to_unsafe_hash.symbolize_keys
        @inventory = current_inventory_pool.inventory params
        set_pagination_header(@inventory) unless params[:paginate] == 'false'
      end
    end
  end

  def show
    @record = \
      current_inventory_pool
        .items
        .find_by('UPPER(inventory_code) = ?', params[:inventory_code].upcase) || \
      current_inventory_pool
        .options
        .find_by('UPPER(inventory_code) = ?', params[:inventory_code].upcase)

    @record ||= \
      begin
        owned_item = \
          current_inventory_pool
          .own_items
          .find_by('UPPER(inventory_code) = ?', params[:inventory_code].upcase)
        if owned_item
          { error: _('You do not have the responsibility to lend this item. ' \
                     "Responsible for this item is the pool \"%s\".") % \
                    owned_item.inventory_pool.name }
        end
      end
  end

  def helper
    @fields = Field.all.select do |f|
      f.accessible_by? current_user, current_inventory_pool
    end
  end

  def helper_react
    @props = {
      inventory_pool_id: current_inventory_pool.id
    }
  end

  def csv_export
    send_data \
      InventoryPool.csv_export(current_inventory_pool, params),
      type: 'text/csv; charset=utf-8; header=present',
      disposition: \
        'attachment; ' \
        "filename=#{current_inventory_pool.shortname}-#{_('Inventory')}.csv"
  end

  def excel_export
    send_data \
      InventoryPool.excel_export(current_inventory_pool, params),
      type: 'application/xlsx',
      disposition: \
        "filename=#{current_inventory_pool.shortname}-#{_('Inventory')}.xlsx"
  end

  def csv_import
    if request.post?
      items = current_inventory_pool.csv_import(current_inventory_pool,
                                                params[:csv_file].tempfile)

      # &:valid?
      @valid_items, @invalid_items = items.partition { |item| item.errors.empty? }
    end
  end

end
