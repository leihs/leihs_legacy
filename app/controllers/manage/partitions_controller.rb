class Manage::PartitionsController < Manage::ApplicationController

  def index
    @partitions = \
      Entitlement.with_generals(
        model_ids: params[:model_ids],
        inventory_pool_id: current_inventory_pool.id
      ).map do |e|
        e.attributes.transform_keys do |k|
          case k
          when 'entitlement_group_id'
            :group_id
          else
            k
          end
        end
      end
  end
end
