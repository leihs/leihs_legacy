module LeihsAdmin
  class SuppliersController < AdminController

    before_action only: [:show, :edit, :update, :destroy] do
      @supplier = Supplier.find(params[:id])
    end

    def index
      filters = params.permit(:search_term, :pool_id)
      @suppliers = Supplier.filter(**filters.to_h.symbolize_keys)
      @suppliers_total_count = Supplier.all.count
      @pools_with_suppliers = InventoryPool.joins(:items)
        .where.not('items.supplier_id': nil).distinct.order(:name)
    end

    def new
      @supplier = Supplier.new
    end

    def create
      @supplier = Supplier.create params[:supplier]
      if @supplier.persisted?
        flash[:notice] = _('Supplier successfully created')
        redirect_to action: :index
      else
        flash.now[:error] = @supplier.errors.full_messages.uniq.join(', ')
        render :new
      end
    end

    def show
      @items = \
        @supplier \
          .items
          .includes(:model, :inventory_pool)
          .group_by(&:inventory_pool)
    end

    alias edit show

    def update
      attrs = params.require(:supplier).permit(:name, :note)
      if @supplier.update_attributes(attrs)
        flash[:notice] = _('Supplier successfully updated')
        redirect_to action: :index
      else
        flash.now[:error] = @supplier.errors.full_messages.uniq.join(', ')
        render :edit
      end
    end

    def destroy
      begin
        @supplier.destroy
        flash[:success] = _('%s successfully deleted') % _('Supplier')
      rescue => e
        flash[:error] = e.to_s
      end
      redirect_to action: :index
    end

  end

end
