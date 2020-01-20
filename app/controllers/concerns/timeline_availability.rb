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
        	and status not in ('rejected', 'closed')
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

      ActiveRecord::Base.connection.exec_query(query).to_hash
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

      ActiveRecord::Base.connection.exec_query(query).to_hash
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

      ActiveRecord::Base.connection.exec_query(query).to_hash
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

      ActiveRecord::Base.connection.exec_query(query).to_hash
    end

    def entitlements(model_id)
      query = <<-SQL
        select
        	entitlements.*
        from
        	entitlements
        where
          model_id = '#{model_id}'
      SQL

      ActiveRecord::Base.connection.exec_query(query).to_hash
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

      ActiveRecord::Base.connection.exec_query(query).to_hash
    end

    def timeline_availability(model_id, inventory_pool_id, is_lending_manager)
      inventory_pool = InventoryPool.find(inventory_pool_id)
      model = Model.find(model_id)

      running_reservations = running_reservations(inventory_pool.id, model.id)
      entitlements = entitlements(model.id)
      reservation_users = reservation_users(running_reservations)
      entitlement_groups_users = entitlement_groups_users(reservation_users)
      entitlement_groups = entitlement_groups(
        entitlements, entitlement_groups_users, inventory_pool.id
      )
      items = items(inventory_pool.id, model.id)

      {
        maintenance_period: model.maintenance_period.to_i,
        running_reservations: running_reservations,
        entitlements: entitlements,
        reservation_users: reservation_users,
        entitlement_groups_users: entitlement_groups_users,
        entitlement_groups: entitlement_groups,
        items: items,
        is_lending_manager: is_lending_manager
      }
    end
  end
end
