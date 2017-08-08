class Manage::ItemsController < Manage::ApplicationController
  include FileStorage

  JSON_SPEC = {
    methods: [:current_location,
              :unique_serial_number?],
    include: {
      inventory_pool: {},
      model: {},
      owner: {},
      supplier: {},
      room: { include: :building }
    }
  }

  def index
    cip = unless params[:current_inventory_pool] == 'false'
             current_inventory_pool
          end
    @items = Item.filter params, cip
    set_pagination_header(@items) unless params[:paginate] == 'false'
  end

  def current_locations
    cip = unless params[:current_inventory_pool] == 'false'
             current_inventory_pool
          end
    items = Item.filter params, cip
    @locations = []
    items.each do |item|
      @locations.push \
        id: item.id,
        location: if current_inventory_pool.owner_or_responsible_for?(item)
                    item.current_location
                  else
                    item.inventory_pool.name
                  end
    end
  end

  def new
    @type = params[:type] ? params[:type] : 'item'
    @item = Item.new(owner: current_inventory_pool)
    @item.inventory_code = Item.proposed_inventory_code(current_inventory_pool)
    unless @current_user.has_role?(:lending_manager, current_inventory_pool)
      @item.inventory_pool = current_inventory_pool
    end
    @item.is_inventory_relevant = (super_user? ? true : false)
  end

  def edit
    fetch_item_by_id
  end

  def create
    @item = Item.new(owner: current_inventory_pool)
    @item.skip_serial_number_validation = skip_serial_number_validation_param

    check_fields_for_write_permissions

    unless @item.errors.any?
      @item.attributes = item_params
      if item_params[:room_id].blank? and @item.license?
        @item.room = Room.general_general
      end
      saved = @item.save
    end

    respond_to do |format|
      format.json do
        if saved
          if params[:copy]
            render(status: :ok,
                   json: { id: @item.id,
                           redirect_url: \
                             manage_copy_item_path(current_inventory_pool,
                                                   @item.id) })
          else
            json = @item.as_json(JSON_SPEC).to_json
            render(status: :ok, json: json)
          end
        else
          if @item
            render \
              json: {
                message: item_errors_full_messages,
                can_bypass_unique_serial_number_validation: \
                  can_bypass_unique_serial_number_validation?(@item)
              },
              status: :bad_request
          else
            render json: {}, status: :not_found
          end
        end
      end
    end
  end

  def update
    fetch_item_by_id

    if @item
      @item.skip_serial_number_validation = skip_serial_number_validation_param

      check_fields_for_write_permissions

      unless @item.errors.any?
        # NOTE avoid to lose already stored properties
        if item_params[:properties]
          item_params[:properties] = \
            @item.properties.merge item_params[:properties].to_unsafe_hash
        end
        saved = @item.update_attributes(item_params)
      end

    end

    respond_to do |format|
      format.json do
        if saved
          if params[:copy]
            render(status: :ok,
                   json: { redirect_url: \
                             manage_copy_item_path(current_inventory_pool,
                                                   @item.id) })
          else
            json = @item.as_json(JSON_SPEC).to_json
            render(status: :ok, json: json)
          end
        else
          if @item
            render \
              json: {
                message: item_errors_full_messages,
                can_bypass_unique_serial_number_validation: \
                  can_bypass_unique_serial_number_validation?(@item)
              },
              status: :bad_request
          else
            render json: {}, status: :not_found
          end
        end
      end
    end
  end

  def copy
    fetch_item_by_id
    @type = @item.type.downcase
    @item = @item.dup
    @item.owner = @current_inventory_pool
    @item.inventory_code = Item.proposed_inventory_code(current_inventory_pool)
    @item.serial_number = nil
    @item.name = nil
    @item.last_check = Date.today
    render :new
  end

  def show
    fetch_item_by_id
  end

  def inspect
    fetch_item_by_id
    [:is_borrowable, :is_incomplete, :is_broken, :status_note].each do |attr|
      @item.update_attributes(attr => params[attr])
    end
    @item.save!
    head :ok
  end

  def upload
    @item = fetch_item_by_id
    params[:files].each do |file|
      if params[:type] == 'attachment'
        store_attachment!(file, item_id: @item.id)
      else
        raise 'Unknown attachment type'
      end
    end
    head :ok
  end

  private

  def fetch_item_by_id
    @item = Item.find params[:id]
  end

  def check_fields_for_write_permissions
    Field.all.each do |field|
      next unless field.data['permissions']
      next unless field.get_value_from_params item_params
      next if field.editable(current_user, current_inventory_pool, @item)
      @item
        .errors
        .add(:base,
             _('You are not the owner of this item') \
             + ', ' \
             + _('therefore you may not be able to change some of these fields'))
    end
  end

  def skip_serial_number_validation_param
    ssnv = params.require(:item).delete(:skip_serial_number_validation)
    if ssnv.try(:==, 'true')
      true
    else
      false
    end
  end

  def can_bypass_unique_serial_number_validation?(item)
    not item.unique_serial_number? and item.errors.size == 1
  end

  def item_errors_full_messages
    # `reverse` because the error message for the serial number
    # should be displayed as last.
    @item.errors.full_messages.reverse.uniq.join(' ')
  end

  def item_params
    params.require(:item)
  end
end
