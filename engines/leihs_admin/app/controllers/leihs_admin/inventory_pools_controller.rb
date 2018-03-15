module LeihsAdmin
  class InventoryPoolsController < AdminController

    def index
      @inventory_pools = InventoryPool.unscoped.search(params[:search_term])
      @inventory_pools = case params[:activity]
                         when nil, 'active'
                           @inventory_pools.where(is_active: true)
                         when 'inactive'
                           @inventory_pools.where(is_active: false)
                         else
                           @inventory_pools
                         end
      @inventory_pools = @inventory_pools.sort
    end

    def new
      @inventory_pool = InventoryPool.new
    end

    def create
      @inventory_pool = InventoryPool.new
      process_params params[:inventory_pool]

      begin
        ApplicationRecord.transaction do
          @inventory_pool.update_attributes!(params[:inventory_pool])
          inventory_managers_access_rights
          create_mail_templates!(@inventory_pool)
        end
        flash[:notice] = _('Inventory pool successfully created')
        redirect_to admin.inventory_pools_path
      rescue => e
        flash.now[:error] = e.message
        render :new
      end
    end

    def edit
      @inventory_pool = InventoryPool.unscoped.find(params[:id])
    end

    def update
      @inventory_pool = InventoryPool.unscoped.find(params[:id])
      process_params params[:inventory_pool]

      if @inventory_pool.update_attributes(params[:inventory_pool])
        inventory_managers_access_rights
        flash[:notice] = _('Inventory pool successfully updated')
        redirect_to admin.edit_inventory_pool_path(@inventory_pool)
      else
        flash.now[:error] = @inventory_pool.errors.full_messages.uniq.join(', ')
        render :edit
      end
    end

    def destroy
      begin
        InventoryPool.unscoped.find(params[:id]).destroy
        respond_to do |format|
          format.json { head :ok }
          format.html do
            flash[:success] = _('%s successfully deleted') % _('Inventory Pool')
            redirect_to action: :index
          end
        end
      rescue => e
        respond_to do |format|
          format.json { head :bad_request }
          format.html do
            flash[:error] = e
            redirect_to action: :index
          end
        end
      end
    end

    private

    def create_mail_templates!(inventory_pool)
      MailTemplate.where(is_template_template: true).each do |mt|
        MailTemplate.create! \
          mt.attributes
          .reject { |k, _| k == 'id' }
          .merge(is_template_template: false,
                 inventory_pool_id: inventory_pool.id)
      end
    end

    def process_params(ip)
      ip[:email] = nil if params[:inventory_pool][:email].blank?
    end

    def inventory_managers_access_rights
      to_delete = existing_inventory_manager_ids - submitted_inventory_manager_ids
      to_delete.each do |id|
        user = User.find id
        ar = user.access_right_for(@inventory_pool)
        ar.update_attributes! role: :customer
      end
      to_add = submitted_inventory_manager_ids - existing_inventory_manager_ids
      to_add.each do |id|
        user = User.find id
        ar = \
          user
          .access_rights
          .find_or_initialize_by(inventory_pool: @inventory_pool)
        ar.update_attributes!(role: :inventory_manager, deleted_at: nil)
      end
    end

    def existing_inventory_manager_ids
      @existing_inventory_manager_ids ||= \
        @inventory_pool \
          .users
          .inventory_managers
          .pluck(:id)
          .sort
    end

    def submitted_inventory_manager_ids
      @submitted_inventory_manager_ids ||= \
        if params[:inventory_managers] and params[:inventory_managers][:user_ids]
          params[:inventory_managers][:user_ids].sort
        else
          []
        end
    end
  end
end
