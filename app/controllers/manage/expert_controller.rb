class Manage::ExpertController < Manage::ApplicationController
  include ExpertView
  include ExpertExport

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
      format.json do
        @inventory = items_for_view(current_inventory_pool, params)
      end
    end
  end

  def csv_export
    send_data \
      csv_export_expert(current_inventory_pool, params),
      type: 'text/csv; charset=utf-8; header=present',
      disposition: \
        'attachment; ' \
        "filename=#{current_inventory_pool.shortname}-#{_('Inventory')}.csv"
  end

  def excel_export
    send_data \
      excel_export_expert(current_inventory_pool, params),
      type: 'application/xlsx',
      disposition: \
        "filename=#{current_inventory_pool.shortname}-#{_('Inventory')}.xlsx"
  end
end
