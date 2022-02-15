module Availability

  ETERNITY = Date.parse('3000-01-01')

  class Changes < Hash

    def between(date1, date2)
      # start from most recent entry we have, which is the last before date1
      most_recent_date = most_recent_before_or_equal(date1) || date1
      dates_between = keys & (most_recent_date..date2).to_a
      Hash[dates_between.map { |d| [d, self[d]] }]
    end

    def end_date_of(date)
      first_after(date).try(:yesterday) || Availability::ETERNITY
    end

    # If there isn't a change on "date" then a new change will be added
    # with the given "date". The newly created change will have the
    # same quantities associated as the change preceding it.
    def insert_changes_and_get_inner(date1, date2)
      [date1, date2.tomorrow].each do |date|
        self[date] ||=
          begin
            group_allocations = self[most_recent_before_or_equal(date)]
            # NOTE: we copy values (we don't want references with .dup)
            Marshal.load(Marshal.dump(group_allocations))
          end
      end
      between(date1, date2)
    end

    private

    # returns a change, the last before the date argument
    def most_recent_before_or_equal(date)
      keys.select { |x| x <= date }.max
    end

    # returns a change, the first after the date argument
    def first_after(date)
      keys.select { |x| x > date }.min
    end

  end

  #########################################################

  class Main
    attr_reader(:running_reservations,
                :entitlements,
                :changes,
                :inventory_pool_and_model_group_ids)

    # exclude_reservations are used in borrow for dealing with the self-blocking
    # aspect of the reservations (context: change quantity for a model
    # in current order)
    def initialize(model:, inventory_pool:, exclude_reservations:)
      exclude_reservations = (exclude_reservations.presence || [])

      @model          = model
      @inventory_pool = inventory_pool
      # NOTE: reservation's default_scope is:
      # { order(:created_at) }
      @running_reservations = \
        @inventory_pool
        .running_reservations
        .where(model_id: @model.id)
        .where.not(id: exclude_reservations)

      @entitlements = Entitlement.hash_with_generals(@inventory_pool, @model)

      @inventory_pool_and_model_group_ids = \
        Entitlement
        .joins(:entitlement_group)
        .where(model: @model,
               entitlement_groups: { inventory_pool: @inventory_pool })
        .order('entitlement_groups.name ASC')
        .map(&:entitlement_group_id)

      initial_group_allocations = {}
      @entitlements.each_pair do |group_id, quantity|
        initial_group_allocations[group_id] = { in_quantity: quantity,
                                                running_reservations: [] }
      end

      @changes = Changes[Time.zone.today => initial_group_allocations]

      @running_reservations.each do |reservation|
        reservation_user_group_ids = reservation.user_group_ids

        ##################### START DATE: DON'T RECALCULATE PAST ##################

        unavailable_from = if reservation.item_id
                             Time.zone.today
                           else
                             [reservation.start_date, Time.zone.today].max
                           end

        ######################### EXTEND END DATE #################################
        # If overdue, extend end_date to today.
        #
        # Given a reservation is running until the 24th and
        # the maintenance period is 1 (working!) day and
        # there are no holidays and the pool is open 7 days a week
        # (which is not the case normally, but just to make it simpler):
        #
        # - If today is the 15th,
        #   then the item is available again from the 26th of current month.
        #   (25th is used for maintenance)
        #
        # - If today is the 27th,
        #   then the item is available again from the 29th of next month.
        #   (28th is used for maintenance)
        #
        # - If today is the 28th of next month,
        #   then the item is available again from the 30th of next month.
        #   (29th is used for maintenance)
        #
        # The replacement_interval is 1 month.

        unavailable_until = \
          [
            (reservation.late? ? Time.zone.today + 1.month : reservation.end_date),
            Time.zone.today
          ].max

        unavailable_until = @model.being_maintained_until(@inventory_pool,
                                                          unavailable_until)

        ###################### GROUP ALLOCATIONS ##################################
        inner_changes = \
          @changes.insert_changes_and_get_inner(unavailable_from,
                                                unavailable_until)

        ###################### GROUP ALLOCATIONS ##################################
        # this is the order on the groups we check on:
        # 1. groups that this particular reservation can be possibly assigned to,
        #    TODO: sort groups by quantity desc ??
        # 2. general group
        # 3. groups which the user is not even member of

        user_groups = \
          (reservation_user_group_ids & @inventory_pool_and_model_group_ids)
        general_group = [EntitlementGroup::GENERAL_GROUP_ID]
        not_user_groups = \
          (@inventory_pool_and_model_group_ids - reservation_user_group_ids)

        groups_to_check = (user_groups + general_group + not_user_groups)

        max_possible_quantities_for_groups_and_changes =
          max_possible_quantities_for_groups_and_changes(groups_to_check,
                                                         inner_changes)

        reservation.allocated_group_id = groups_to_check.detect do |group_id|
          (max_possible_quantities_for_groups_and_changes[group_id] || 0) >=
            reservation.quantity
        end

        # if still no group has enough available quantity,
        # we allocate to general as fallback
        reservation.allocated_group_id ||= EntitlementGroup::GENERAL_GROUP_ID

        inner_changes.each_pair do |_date, group_allocations|
          group_allocation = group_allocations[reservation.allocated_group_id]
          group_allocation[:in_quantity] -= reservation.quantity
          group_allocation[:running_reservations] << reservation.id
        end
        ###########################################################################
      end
    end

    def maximum_available_in_period_for_groups(start_date, end_date, group_ids)
      max_possible_quantities_for_groups_and_changes(
        [EntitlementGroup::GENERAL_GROUP_ID] + \
          (group_ids & @inventory_pool_and_model_group_ids),
        @changes.between(start_date, end_date)
      ).values.max
    end

    def maximum_available_in_period_summed_for_groups(start_date,
                                                      end_date,
                                                      group_ids = nil)
      group_ids ||= @inventory_pool_and_model_group_ids
      summed_quantities_for_groups_and_changes(
        [EntitlementGroup::GENERAL_GROUP_ID] + \
          (group_ids & @inventory_pool_and_model_group_ids),
        @changes.between(start_date, end_date)
      ).min
    end

    def available_total_quantities
      # sort by date !!!
      Hash[@changes.sort].map do |date, change|
        total = change.values.sum { |val| val[:in_quantity] }
        groups = change.map do |g, q|
          q.merge(group_id: g)
        end
        [date, total, groups]
      end
    end

    private

    # returns a Hash {group_id => quantity}
    def summed_quantities_for_groups_and_changes(group_ids, inner_changes)
      inner_changes.map do |date, change|
        change
          .select { |group_id, _| group_ids.include?(group_id) }
          .values
          .map { |stock_information| stock_information[:in_quantity] }
          .sum
      end
    end

    # returns a Hash {group_id => quantity}
    def max_possible_quantities_for_groups_and_changes(group_ids,
                                                       inner_changes = nil)
      inner_changes ||= @changes
      result = {}
      group_ids.each do |group_id|
        values = inner_changes.values.map do |group_allocations|
          Integer(
            group_allocations[group_id].try(:fetch, :in_quantity).presence || 0
          )
        end
        result[group_id] = values.min
      end
      result
    end

  end
end
