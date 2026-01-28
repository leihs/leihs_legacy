require 'csv'

class Manage::ItemsController < Manage::ApplicationController
  
  include FileStorage
  include ManageInventoryMenu
  include BarcodeHelper

  BATCH_CREATE_MAX_QUANTITY = 100
  
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

  def initialize_and_save_item(inv_code = nil, with_copy_defaults = false)
    item = Item.new(owner: current_inventory_pool)
    # item.skip_serial_number_validation = skip_serial_number_validation_param

    item_params = get_item_params!(inv_code)
    check_fields_for_write_permissions(item, item_params)

    unless item.errors.any?
      item.attributes = item_params
      if item.attributes[:room_id].blank? and item.license?
        item.room = Room.general_general
      end
      set_copy_defaults(item) if with_copy_defaults
      item.save

      params[:child_items]&.each do |child_id|
        child = Item.find(child_id)
        child.skip_serial_number_validation = true
        child.parent = item
        child.save!
      end
    end

    item
  end

  def create_multiple
    ApplicationRecord.transaction(requires_new: true) do
      items = 
        Item
        .free_consecutive_inventory_codes(current_inventory_pool, quantity_param)
        .map do |inv_code|
          initialize_and_save_item(inv_code, :with_copy_defaults) 
        end

      respond_to do |format|
        format.json do
          if items.all?(&:persisted?)
            render(status: :ok,
                   json: { redirect_url:
                           manage_create_multiple_items_result_path(
                             current_inventory_pool,
                             ids: items.map(&:id)
                           )})
          else
            errors = 
              items
              .map { |i| item_errors_full_messages(i) }
              .flatten
            render(json: { message: errors }, status: :bad_request)
            raise ActiveRecord::Rollback
          end
        end
      end
    end
  end

  def create_multiple_result
    created_items = Item.find(params[:ids])
    created_items_json = created_items.map do |i| 
      i.as_json(JSON_SPEC).merge(
        barcode: barcode_for_item(i),
        url: manage_edit_item_url(current_inventory_pool, i, url_options_that_work_in_prod))
    end
    date = created_items.first.created_at
    csv_url = manage_create_multiple_items_result_path(current_inventory_pool, ids: params[:ids], format: :csv)
    csv_filename = "leihs-items-#{date.strftime('%Y-%m-%d_%H-%M-%S')}.csv"
    view_data = { items: created_items_json, date: date, csv_url: csv_url, csv_filename: csv_filename}
    
    respond_to do |format|
      format.html do
        @props = view_data.merge(menu: manage_inventory_menu)
        render(status: :ok)
      end
      format.csv { send_created_items_csv(created_items_json, csv_filename) }
    end
  end

  def create
    ApplicationRecord.transaction(requires_new: true) do
      item = initialize_and_save_item

      respond_to do |format|
        format.json do
          if item.persisted?
            if params[:copy]
              render(status: :ok,
                     json: { id: item.id,
                             redirect_url: \
                               manage_copy_item_path(current_inventory_pool,
                                                     item.id) })
            else
              json = item.as_json(JSON_SPEC).to_json
              render(status: :ok, json: json)
            end
          else
            if item
              render \
                json: {
                  message: item_errors_full_messages(item),
                  can_bypass_unique_serial_number_validation: \
                    can_bypass_unique_serial_number_validation?(item)
                },
                status: :bad_request
            else
              render json: {}, status: :not_found
            end
          end
        end
      end
    end
  end

  def update
    ApplicationRecord.transaction(requires_new: true) do
      fetch_item_by_id
      item_params = get_item_params!

      if @item
        # @item.skip_serial_number_validation = skip_serial_number_validation_param

        check_fields_for_write_permissions(@item, item_params)

        unless @item.errors.any?
          # NOTE avoid to lose already stored properties
          if item_params[:properties]
            item_params[:properties] = \
              @item.properties.merge item_params[:properties].to_unsafe_hash
          end

          @item.update!(item_params)

          if params[:child_items]
            @item.children = []
            @item.save!
            begin
              params[:child_items]&.each do |child_id|
                child = Item.find(child_id)
                child.parent = @item
                child.skip_serial_number_validation = true
                child.save!
              end
            rescue => e
              @item.errors.add(:base, e.message)
              raise(e)
            end
          end
        end
      end

      respond_to do |format|
        format.json do
          if params[:copy]
            render(status: :ok,
                   json: { redirect_url: \
                           manage_copy_item_path(current_inventory_pool,
                                                 @item.id) })
          else
            json = @item.as_json(JSON_SPEC).to_json
            render(status: :ok, json: json)
          end
        end
      end
    end

  rescue => e
    respond_to do |format|
      format.json do
        if @item
          render \
            json: {
              message: item_errors_full_messages(@item),
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

  def set_copy_defaults(item)
    item.owner = current_inventory_pool
    item.serial_number = nil
    item.name = nil
    item.last_check = Date.today
    item.attachments = []
  end

  def copy
    fetch_item_by_id
    @type = @item.type.downcase
    @item = @item.dup
    @item.inventory_code = Item.proposed_inventory_code(current_inventory_pool)
    set_copy_defaults(@item)

    @props = {
      next_code: Item.proposed_inventory_code(current_inventory_pool),
      lowest_code: Item.proposed_inventory_code(current_inventory_pool, :lowest),
      highest_code: Item.proposed_inventory_code(current_inventory_pool, :highest),
      inventory_pool: current_inventory_pool,
      is_inventory_relevant: (super_user? ? true : false),
      save_path: manage_create_item_path,
      save_multiple_path: manage_create_multiple_items_path,
      store_attachment_path: manage_item_store_attachment_react_path,
      inventory_path: manage_inventory_path,

      item: @item.as_json(Manage::ItemsController::JSON_SPEC),
      item_type: @item.type.downcase,
      attachments: []
    }

    render :new
  end

  def show
    fetch_item_by_id
  end

  def inspect
    fetch_item_by_id
    [:is_borrowable, :is_incomplete, :is_broken, :status_note].each do |attr|
      @item.update(attr => params[attr])
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

  def new
    next_code = Item.proposed_inventory_code(current_inventory_pool)
    if params[:forPackage] == 'true'
      next_code = 'P-' + next_code
    end

    @props = {
      next_code: next_code,
      lowest_code: Item.proposed_inventory_code(current_inventory_pool, :lowest),
      highest_code: Item.proposed_inventory_code(current_inventory_pool, :highest),
      code_prefix: Item.prefix_for_inventory_code(current_inventory_pool),
      inventory_pool: current_inventory_pool,
      is_inventory_relevant: (super_user? ? true : false),
      save_path: manage_create_item_path,
      save_multiple_path: manage_create_multiple_items_path,
      store_attachment_path: manage_item_store_attachment_react_path,
      inventory_path: manage_inventory_path,
      item_type: (params[:type] == 'license' ? 'license' : 'item'),
      for_package: params[:forPackage] == 'true',
      return_url: (params[:return_url] ? params[:return_url] : nil)
    }
  end

  def edit
    item = fetch_item_by_id

    parent = nil
    if item.parent
      parent = {
        json: item.parent.as_json(
          Manage::ItemsController::JSON_SPEC),
        edit_path: manage_edit_item_path(current_inventory_pool, item.parent)
      }
    end

    children = nil
    if item.children && item.children.length > 0
      children = item.children.map do |child|
        {
          json: child.as_json(
            Manage::ItemsController::JSON_SPEC),
          edit_path: manage_edit_item_path(current_inventory_pool, child)
        }
      end
    end

    attachments = @item.attachments.map do |attachment|
      {
        id: attachment.id,
        filename: attachment.filename,
        public_filename: get_attachment_path(attachment.id),
        content_type: attachment.content_type
      }
    end

    model_attachments = @item.model.attachments.map do |attachment|
      {
        id: attachment.id,
        filename: attachment.filename,
        public_filename: get_attachment_path(attachment.id)
      }
    end

    @props = {
      can_destroy: item.can_destroy?,
      edit: true,
      item: item.as_json(Manage::ItemsController::JSON_SPEC),
      item_type: item.type.downcase,
      inventory_pool: current_inventory_pool,
      save_path: manage_update_item_path,
      store_attachment_path: manage_item_store_attachment_react_path,
      inventory_path: manage_inventory_path,
      parent: parent,
      children: children,
      attachments: attachments,
      model_attachments: model_attachments,
      return_url: (params[:return_url] ? params[:return_url] : nil),
      for_package: item.model.is_package
    }
  end

  Mime::Type.register(
    'application/octet-stream', :plist_binary, [], ['binary.plist'])
  def store_attachment_react
    respond_to do |format|
      format.plist_binary do
        store_attachment!(
          params[:data],
          item_id: params[:item_id]
        )
      end
    end
  end

  private

  def fetch_item_by_id
    @item = Item.find params[:id]
    unless current_inventory_pool.owner_or_responsible_for?(@item)
      raise ActiveRecord::RecordNotFound
    end
    return @item
  end

  def check_keys_in_hash_recursive(keys, hash)
    return false if keys.length == 0
    if hash.key?(keys.first)
      if keys.length == 1
        true
      else
        check_keys_in_hash_recursive(keys.from(1), hash[keys.first])
      end
    else
      false
    end
  end

  def field_data_in_params?(field, params)
    if field.id == 'attachments'
      return false
    end
    if field.data['attribute'].is_a? Array
      check_keys_in_hash_recursive(field.data['attribute'], params)
    else
      params.key?(field.data['attribute'])
    end
  end

  def check_fields_for_write_permissions(item, item_params)
    Field.all.each do |field|
      next unless field.data['permissions']
      next unless field_data_in_params?(field, item_params)
      next if field.editable(current_user, current_inventory_pool, item)
      item
       .errors
       .add(:base,
            _('You are not the owner of this item') \
            + ', ' \
            + _('therefore you may not be able to change some of these fields'))
    end
  end

  # def skip_serial_number_validation_param
  #   ssnv = params.require(:item).fetch(:skip_serial_number_validation)
  #   if ssnv.try(:==, 'true')
  #     true
  #   else
  #     false
  #   end
  # end

  def can_bypass_unique_serial_number_validation?(item)
    not item.unique_serial_number? and item.errors.size == 1
  end

  def item_errors_full_messages(item)
    # `reverse` because the error message for the serial number
    # should be displayed as last.
    item.errors.full_messages.reverse.uniq.join(' ')
  end

  def get_item_params!(inv_code = nil)
    item_ps = params.require(:item)
    item_ps[:inventory_code] = inv_code if inv_code
    ###############################################################################
    # convert `skip_serial_number_validation` to boolean
    ###############################################################################
    ssnv = item_ps.fetch(:skip_serial_number_validation, false)
    item_ps[:skip_serial_number_validation] = if ssnv.try(:==, 'true')
                                                true
                                              else
                                                false
                                              end
    ###############################################################################
    item_ps
  end

  def send_created_items_csv(items_data, filename)
    code_prefix = current_inventory_pool.shortname
    header = ['inventory code', 'code prefix', 'code numeric', 'item UUID', 'creation date', 'model name', 'model UUID']
    rows = items_data.map do|itm|
      inv_code = itm['inventory_code']
      name = "#{itm['model']['product']} #{itm['model']['version']}".strip
      [inv_code, code_prefix, inv_code.split(code_prefix).last, itm['id'], itm['created_at'], name, itm['model']['id']]
    end
    data = [header].concat(rows).map {|row| row.to_csv}.join
    send_data(data, type: 'text/csv', disposition: "attachment; filename=#{filename}")
  end

  def quantity_param
    q = params.require(:quantity).to_i
    if q <= 0
      raise 'Quantity param not provided or smaller than 1.'
    elsif q > BATCH_CREATE_MAX_QUANTITY
      raise "Quantity can not be larger than #{BATCH_CREATE_MAX_QUANTITY}."
    else
      q
    end
  end

  # FIXME: generalize this
  def url_options_that_work_in_prod
    external_base_url = ActiveRecord::Base.connection.execute('SELECT external_base_url FROM system_and_security_settings;').first.values.first
    u = URI.parse(external_base_url)
    { host: u.host, port: u.port }
  rescue => err
    Rails.logger.warn("Could not get external_base_url config! [#{err}]")
    nil
  end
  
end
