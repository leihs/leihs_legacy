class Manage::VisitsController < Manage::ApplicationController

  def index
    respond_to do |format|
      format.html do
        @props = { inventory_pool_id: current_inventory_pool.id,
                   start_date: params[:start_date],
                   end_date: params[:end_date],
                   tab: params[:tab] }
      end
      format.json do
        visits = Visit.filter2(params, current_inventory_pool)
        if params[:paginate] == 'false'
          visits = \
            current_inventory_pool
            .visits
            .filter2(params)
            .includes(user: :notifications)
            .where(type: type_param)
            .where(is_approved: true)
            .offset(offset_param)
            .limit(limit_param)

          visits_json = visits.as_json(
            include: [{ user: { methods: :image_url,
                                include: :delegator_user } },
                      :reservations]
          )

          visits_json.each do |v|
            user = User.find(v['user_id'])

            v['user']['is_suspended'] = user.suspended?(current_inventory_pool)

            # NOTE: `extended_info` not needed and some records even contain
            # invalid UTF8 chars!
            v['user']['extended_info'] = nil

            v['reservations'].each do |r|
              object = \
                Model.find_by_id(r['model_id']) ||
                Option.find_by_id(r['option_id'])
              r['model_name'] = object.name
            end

            v['notifications'] = \
              user.notifications.where('created_at >= ?', v['date']).limit(10)
          end

          render json: visits_json and return
        else
          @visits = visits.default_paginate(params)
          # NOTE: `total_entries` from will_paginate gem does not
          # work with our custom `Visit.default_scope`, thus we
          # use our own `Visit.total_count_for_paginate`
          headers['X-Pagination'] = {
            total_count: visits.total_count_for_paginate,
            per_page: @visits.per_page,
            offset: @visits.offset
          }.to_json
        end
      end
    end
  end

  def destroy
    visit = \
      current_inventory_pool
      .visits
      .hand_over
      .find(params[:visit_id])

    ActiveRecord::Base.transaction do
      visit.reservations.each(&:destroy!)
    end

    head :ok
  end

  def remind
    visit = \
      current_inventory_pool
      .visits
      .take_back
      .find(params[:visit_id])

    # TODO: dry with User.remind_and_suspend_all
    grouped_reservations = visit.reservations.group_by do |vl|
      { inventory_pool: vl.inventory_pool,
        user_id: (vl.delegated_user_id || vl.user_id) }
    end
    grouped_reservations.each_pair do |k, reservations|
      user = User.find(k[:user_id])
      user.remind(reservations)
    end

    head :ok
  end

  private

  def type_param
    params.require(:type)
  end

  def offset_param
    p = params.require(:offset)
    p.match?(/\d*/) ? p : raise(ActionController::UnpermittedParameters)
  end

  def limit_param
    p = params.require(:limit)
    p.match?(/\d*/) ? p : raise(ActionController::UnpermittedParameters)
  end

end
