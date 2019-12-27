class Borrow::ModelsController < Borrow::ApplicationController

  def availability
    models = current_user.models.borrowable.where(id: params[:model_ids])
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    inventory_pools = \
      current_user.inventory_pools.where(id: params[:inventory_pool_ids])
    @availability = models.map do |model|
      inventory_pools.map do |ip|
        {
          model_id: model.id,
          inventory_pool_id: ip.id,
          quantity: \
            model
              .availability_in(ip)
              .maximum_available_in_period_summed_for_groups(
                start_date, end_date, current_user.entitlement_groups.map(&:id)
              )
        }
      end
    end
    @availability.flatten!
  end

  def index
    @category = Category.find_by_id params[:category_id]
    @models = Model.filter params, current_user, @category, true
    set_pagination_header(@models)
    respond_to do |format|
      format.json
      format.html do
        @child_categories = @category.children.select do |c|
          @models.from_category_and_all_its_descendants(c).exists?
        end
        @grand_children = {}
        @child_categories.each do |category|
          @grand_children[category.id] = \
            category.children.select do |c|
              @models.from_category_and_all_its_descendants(c).exists?
            end
        end
        @inventory_pools = \
          current_user.inventory_pools.with_borrowable_items.order(:name)

        # used for React booking calendar #########################################
        @inventory_pools_for_calendar = @inventory_pools.map do |ip|
          { inventory_pool: ip,
            workday: ip.workday,
            holidays: \
              ip.holidays.where("'#{Date.today}' <= end_date").order(:end_date) }
        end
        ###########################################################################
      end
    end
  end

  def show
    @model = current_user.models.borrowable.find(params[:id])
    @inventory_pools = current_user.inventory_pools.order(:name).map do |ip|
      {
        inventory_pool: ip,
        workday: ip.workday,
        holidays: \
        ip.holidays.where('CURRENT_DATE <= end_date').order(:end_date),
        total_borrowable: \
          @model.total_borrowable_items_for_user_and_pool(
            current_user,
            ip,
            ensure_non_negative_general: true
          )
      }
    end
      .select { |ip_context| ip_context[:total_borrowable].positive? }

    respond_to do |format|
      format.json
      format.html
    end
  end

end
