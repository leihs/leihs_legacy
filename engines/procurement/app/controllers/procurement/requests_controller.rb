require_dependency 'procurement/application_controller'
require_dependency 'procurement/concerns/filter'

module Procurement
  # rubocop:disable Metrics/ClassLength
  class RequestsController < ApplicationController
    include Filter

    before_action do
      if procurement_inspector? or procurement_admin?
       if params[:user_id]
         @user = User.not_as_delegations.find(params[:user_id])
       end
      else # only requester
        @user = current_user
      end

      if params[:category_id]
        @category = Procurement::Category.find(params[:category_id])
      end

      if params[:budget_period_id]
        @budget_period = BudgetPeriod.find(params[:budget_period_id])
      end

      unless RequestPolicy.new(current_user, request_user: @user).allowed?
        raise Pundit::NotAuthorizedError
      end
    end

    # rubocop:disable Metrics/MethodLength
    def index
      h = { budget_period_id: @budget_period }
      h[:user_id] = @user if @user
      h[:category_id] = @category if @category
      @requests = Request.where h
      @buildings = Building.all
      @rooms = [Room.general_general]
      @for_inline_edit = request.xhr?

      respond_to do |format|
        format.html do
          render(layout: !@for_inline_edit)
        end
        format.csv do
          send_data Request.csv_export(@requests, current_user),
                    type: 'text/csv; charset=utf-8; header=present',
                    disposition: "attachment; filename=#{_('Requests')}.csv"
        end
        format.xlsx do
          send_data Request.excel_export(@requests, current_user),
                    type: 'application/xlsx',
                    disposition: "filename=#{_('Requests')}.xlsx"
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # render edit form for a single request (PJAX)
    def edit
      @request = Request.find(id_param)
      @user = @request.user

      unless RequestPolicy.new(current_user, request_user: @user).allowed?
        raise Pundit::NotAuthorizedError
      end

      @buildings = Building.all
      @rooms = [Room.general_general]
      @category = @request.category
      @budget_period = @request.budget_period

      render layout: !request.xhr?
    end

    # update a single request
    def update
      @request = Request.find(id_param)
      @category = @request.category

      request_params = params.require(:requests).require(@request.id)
      handle_attachments! request_params
      permitted = permit_request_attributes(request_params,
                                            category: @category,
                                            user: @request.user)

      r = update_request(params, permitted)
      if r.errors.any?
        render json: r.errors.full_messages, status: 422
      else
        render layout: !request.xhr?, locals: { r: r }, format: 'html'
      end
    end

    def overview
      respond_to do |format|
        format.html { default_filters }
        format.js do
          @h = get_requests
          render partial: 'overview'
        end
        format.csv do
          requests = get_requests.values.flatten
          send_data Request.csv_export(requests, current_user),
                    type: 'text/csv; charset=utf-8; header=present',
                    disposition: "attachment; filename=#{_('Requests')}.csv"
        end
        format.xlsx do
          requests = get_requests.values.flatten
          send_data Request.excel_export(requests, current_user),
                    type: 'application/xlsx',
                    disposition: "filename=#{_('Requests')}.xlsx"
        end
      end
    end

    def new
      authorize @budget_period, :not_past?
    end

    def create
      errors = create_or_update

      if errors.empty?
        flash[:success] = _('Saved')
        head :ok
      else
        render json: errors, status: :internal_server_error
      end
    end

    def move
      @request = Request.where(user_id: @user, category_id: @category,
                               budget_period_id: @budget_period).find(params[:id])

      if params[:to_category_id]
        @request.category = Procurement::Category.find(params[:to_category_id])
      elsif params[:to_budget_period_id]
        @request.budget_period = BudgetPeriod.find(params[:to_budget_period_id])
      end

      # not to be moved
      @request.approved_quantity = nil
      @request.order_quantity = nil

      # reset to default value if moved to a category
      # not inspectable by current user
      unless @request.category.inspectable_by?(current_user)
        @request.inspector_priority = :medium
      end

      if @request.save
        render partial: 'layouts/procurement/flash',
               locals: { flash: { success: _('Request moved') } }
      else
        render status: :bad_request
      end
    end

    def destroy
      request = Request.where(user_id: @user, category_id: @category,
                              budget_period_id: @budget_period).find(params[:id])
      request.destroy
      if request.destroyed?
        render partial: 'layouts/procurement/flash',
               locals: { flash: { success: _('Deleted') } }
      else
        render status: :bad_request
      end
    end

    private

    def id_param
      params.require(:id)
    end

    def handle_attachments!(params_x)
      if params_x[:attachments_attributes]
        transform_attachment_files_into_attributes! \
          params_x[:attachments_attributes]
      end
    end

    def create_or_update
      params.require(:requests).values.map do |param|
        handle_attachments! param

        permitted = \
          permit_request_attributes(param, category: @category, user: @user)

        if param[:id]
          r = update_request(param, permitted)
        else
          next if permitted[:motivation].blank?
          r = @category.requests.create(permitted) do |x|
            x.user = @user
            x.budget_period = @budget_period
          end
        end
        r.errors.full_messages
      end.flatten.compact
    end

    def update_request(param, permitted)
      r = Request.find(param[:id])

      # NOTE: hacky, 2nd case is for single `#update`
      attachments_to_delete = param[:attachments_delete] \
        || param.try(:fetch, :requests, nil).try(:fetch, r.id.to_sym, nil)
                .try(:fetch, :attachments_delete, nil)

      if attachments_to_delete
        attachments_to_delete.each_pair do |k, v|
          r.attachments.destroy(k) if v == '1'
        end
      end
      r.update_attributes(permitted)
      r
    end

    def transform_attachment_files_into_attributes!(array_of_file_hashes)
      array_of_file_hashes.map! do |h|
        if h.empty?
          {}
        else
          file = h['file']
          unless file.blank?
            attachment_attributes(file)
          end
        end
      end
    end

    def attachment_attributes(file)
      attrs = {}
      attrs['content'] = Base64.encode64(file.read)
      attrs['filename'] = file.original_filename
      attrs['size'] = file.size
      attrs['content_type'] = file.content_type
      attrs['metadata'] = MetadataExtractor.new(file.tempfile.path).to_hash
      attrs
    end

    def initialize_keys(category:, new_request: false)
      keys = Request::REQUESTER_EDIT_KEYS
      if category.inspectable_by?(current_user)
        keys += Request::INSPECTOR_KEYS
      end
      if new_request
        keys += Request::REQUESTER_NEW_KEYS
      end
      keys
    end

    def permit_request_attributes(r_params, category:, user:)
      new_request = r_params[:id].blank? || user == current_user
      keys = initialize_keys(category: category, new_request: new_request)
      r_params.permit(keys)
    end

  end
  # rubocop:enable Metrics/ClassLength
end
