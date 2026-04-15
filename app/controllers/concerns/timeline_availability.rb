module TimelineAvailability
  extend ActiveSupport::Concern

  included do

    private

    def running_reservations(inventory_pool_id, model_id)
      timeout_at = Time.now.utc - Setting.first.timeout_minutes.minutes
      today = Time.zone.today
      query = ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL,
           select
            reservations.*
           from
            reservations
           where
            reservations.inventory_pool_id = ?
            and status not in ('draft', 'rejected', 'canceled', 'closed')
            and model_id = ?
            and reservations.type = 'ItemLine'
            and not (
              status = 'unsubmitted' and
              updated_at < ?
            )
            and not (
              end_date < ? and
              item_id is null
            )
         SQL
         inventory_pool_id, model_id, timeout_at, today]
      )

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def reservation_users(reservations)
      user_ids = reservations.map { |r| r['user_id'] }

      return [] if user_ids.empty?

      query = ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL,
           select
            users.*
           from
            users
           where
            users.id in (?)
         SQL
         user_ids]
      )

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def entitlement_groups_users(users)
      user_ids = users.map { |r| r['id'] }

      return [] if user_ids.empty?

      query = ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL,
           select
            entitlement_groups_users.*
           from
            entitlement_groups_users
           where
            user_id in (?)
         SQL
         user_ids]
      )

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

      ids = group_ids.compact.uniq
      return [] if ids.empty?

      query = ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL,
           select
            entitlement_groups.*
           from
            entitlement_groups
           where
            entitlement_groups.id in (?)
            and entitlement_groups.inventory_pool_id = ?
         SQL
         ids, inventory_pool_id]
      )

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def entitlements(model_id, pool_id)
      query = ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL,
           SELECT entitlements.*
           FROM entitlements
           JOIN entitlement_groups
             ON entitlement_groups.id = entitlements.entitlement_group_id
           WHERE model_id = ?
             AND entitlement_groups.inventory_pool_id = ?
         SQL
         model_id, pool_id]
      )

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def items(inventory_pool_id, model_id)
      query = ActiveRecord::Base.sanitize_sql_array(
        [<<~SQL,
           select
            items.*
           from
            items
           where
            items.inventory_pool_id = ?
            and items.model_id = ?
            and items.parent_id is null
         SQL
         inventory_pool_id, model_id]
      )

      ActiveRecord::Base.connection.exec_query(query).to_a
    end

    def timeline_availability(model_id, inventory_pool_id, is_lending_manager)
      inventory_pool = InventoryPool.find(inventory_pool_id)
      model = Model.find(model_id)

      running_reservations = running_reservations(inventory_pool.id, model.id)
      entitlements = entitlements(model.id, inventory_pool.id)
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
