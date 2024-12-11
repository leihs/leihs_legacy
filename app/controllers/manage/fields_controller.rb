class Manage::FieldsController < Manage::ApplicationController

  def index
    @fields = Field.all.select do |f|
      [params[:target_type], nil].include?(f.data['target_type']) \
        and (
          f.accessible_by?(current_user, current_inventory_pool) ||
          f.id == 'inventory_code'
        ) \
        and not (exclude_checkbox_param and f.data['type'] == 'checkbox') \
        and not DisabledField.find_by(
          inventory_pool_id: current_inventory_pool.id,
          field_id: f.id
        )
    end.sort_by do |f|
      [Field::GROUPS_ORDER.index(f.data['group']) || 999, f.position]
    end
  end

  private

  def exclude_checkbox_param
    params[:exclude_checkbox] == 'true'
  end
end
