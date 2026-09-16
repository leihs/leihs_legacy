module TimelineAvailability
  extend ActiveSupport::Concern

  included do
    private

    def running_reservations(inventory_pool_id, model_id)
      query = <<-SQL
        select
        	reservations.*
        from
        	reservations
        where
        	reservations.inventory_pool_id = '#{inventory_pool_id}'
        	and status not in ('draft', 'rejected', 'canceled', 'closed')
          and model_id = '#{model_id}'
          and reservations.type = 'ItemLine'
          and not (
            status = 'unsubmitted' and
            updated_at < '#{Time.now.utc - Setting.first.timeout_minutes.minutes}'
          )
          and not (
            end_date < '#{Time.zone.today}' and
            item_id is null
          )
      SQL

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    # For reservations with a pickup_location, the timeline should show the
    # reservation as blocking through its transfer-buffer window too, not
    # just its own start_date/end_date.
    def add_timeline_dates!(reservations, inventory_pool)
      reservations.each do |r|
        if r['pickup_location_id']
          r['timeline_start_date'] =
            widened_timeline_date(inventory_pool, r['start_date'],
                                  inventory_pool.transfer_buffer_before_pick_up, step: :-)
          r['timeline_end_date'] =
            widened_timeline_date(inventory_pool, r['end_date'],
                                  inventory_pool.transfer_buffer_after_drop_off, step: :+)
        else
          r['timeline_start_date'] = r['start_date']
          r['timeline_end_date'] = r['end_date']
        end
      end
    end

    def widened_timeline_date(inventory_pool, date, buffer_days, step:)
      inventory_pool.step_orders_processing_days(date.to_date, buffer_days.to_i, step:)
    end

    def reservation_users(reservations)
      user_ids = reservations.map { |r| r['user_id'] }

      return [] if user_ids.empty?

      query = <<-SQL
        select
        	users.*
        from
        	users
        where
        	users.id in (#{user_ids.map { |id| "'#{id}'" }.join(',')})
      SQL

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def entitlement_groups_users(users)
      user_ids = users.map { |r| r['id'] }

      return [] if user_ids.empty?

      query = <<-SQL
        select
        	entitlement_groups_users.*
        from
        	entitlement_groups_users
        where
        	user_id in (#{user_ids.map { |id| "'#{id}'" }.join(',')})
      SQL

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def entitlement_groups(
      entitlements,
      entitlement_groups_users,
      inventory_pool_id
    )
      group_ids = entitlements.map { |e| e['entitlement_group_id'] } \
       + entitlement_groups_users.map { |r| r['entitlement_group_id'] }

      return [] if group_ids.empty?

      query = <<-SQL
        select
        	entitlement_groups.*
        from
        	entitlement_groups
        where
        	entitlement_groups.id in (#{group_ids.map { |id| "'#{id}'" }.join(',')})
          and entitlement_groups.inventory_pool_id = '#{inventory_pool_id}'
      SQL

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def entitlements(model_id, pool_id)
      query = <<-SQL
        SELECT entitlements.*
        FROM entitlements
        JOIN entitlement_groups
          ON entitlement_groups.id = entitlements.entitlement_group_id
        WHERE model_id = '#{model_id}'
          AND entitlement_groups.inventory_pool_id = '#{pool_id}'
      SQL

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def items(inventory_pool_id, model_id)
      query = <<-SQL
        select
        	items.*
        from
        	items
        where
        	items.inventory_pool_id = '#{inventory_pool_id}'
          and items.model_id = '#{model_id}'
          and items.parent_id is null
      SQL

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def pickup_locations(inventory_pool_id)
      query = <<-SQL
        select
        	pickup_locations.*
        from
        	pickup_locations
        where
        	pickup_locations.inventory_pool_id = '#{inventory_pool_id}'
      SQL

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def timeline_availability(model_id, inventory_pool_id, is_lending_manager)
      inventory_pool = InventoryPool.find(inventory_pool_id)
      model = Model.find(model_id)

      running_reservations = running_reservations(inventory_pool.id, model.id)
      add_timeline_dates!(running_reservations, inventory_pool)
      entitlements = entitlements(model.id, inventory_pool.id)
      reservation_users = reservation_users(running_reservations)
      entitlement_groups_users = entitlement_groups_users(reservation_users)
      entitlement_groups = entitlement_groups(
        entitlements, entitlement_groups_users, inventory_pool.id
      )
      items = items(inventory_pool.id, model.id)
      pickup_locations = pickup_locations(inventory_pool.id)

      {
        maintenance_period: model.maintenance_period.to_i,
        running_reservations:,
        entitlements:,
        reservation_users:,
        entitlement_groups_users:,
        entitlement_groups:,
        items:,
        pickup_locations:,
        is_lending_manager:
      }
    end
  end
end
