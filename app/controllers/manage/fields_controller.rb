class Manage::FieldsController < Manage::ApplicationController

  def index
    @fields = Field.all.select do |f|
      [params[:target_type], nil].include?(f.data['target_type']) \
        and (
          f.accessible_by?(current_user, current_inventory_pool) ||
          f.id == 'inventory_code'
        ) \
        and not DisabledField.find_by(
          inventory_pool_id: current_inventory_pool.id,
          field_id: f.id
        )
    end.sort_by do |f|
      [Field::GROUPS_ORDER.index(f.data['group']) || 999, f.position]
    end
  end

  def manage_fields
    @props = {
      fields: Field.all.select do |f|
        (f.accessible_by?(current_user, current_inventory_pool) \
          || f.id == 'inventory_code') && !f.data['required']
        # The to_json parameter is very ugly, check field.rb as_json.
      end.sort_by do |f|
        f.data['label'].downcase
      end.map do |f|
        {
          label: f.data['label'],
          id: f.id,
          target_type: f.data['target_type']
        }
      end,
      disabled_fields: DisabledField.where(
        inventory_pool_id: current_inventory_pool.id
      ),
      inventory_pool_id: current_inventory_pool.id
    }
  end

  def disable_field
    ApplicationRecord.transaction(requires_new: true) do
      inventory_pool = InventoryPool.find(params[:inventory_pool_id])
      field = Field.find(params[:field_id])

      unless field.accessible_by?(current_user, inventory_pool)
        throw 'Not allowed'
      end

      disable = params[:disable] == true

      disabled_field = DisabledField.find_by(
        inventory_pool_id: inventory_pool.id,
        field_id: field.id
      )
      if !disabled_field && disable
        disabled_field = DisabledField.new(
          inventory_pool_id: inventory_pool.id,
          field_id: field.id
        )
        disabled_field.save!
      elsif disabled_field && !disable
        disabled_field.destroy
      end
    end
  end

  def hide
    current_user.hidden_fields.find_or_create_by(field_id: params[:id])
    head :ok
  end

  def reset
    current_user.hidden_fields.destroy_all
    head :ok
  end
end
