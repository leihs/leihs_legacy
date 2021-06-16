contract = Contract.find_by_compact_id!("6ZRE")
user_orig = User.find_by!(firstname: "Matthias", lastname: "Kappeler")
user = User.find_by!(firstname: "Pascal", lastname: "Jeker")
raise "wtf" if contract.user != user_orig

reservations = contract.reservations

ApplicationRecord.transaction(requires_new: true) do
  begin
    ####################################################################
    # Create new orders with the same purpose and pool, but with the
    # new user. It's a copy of the older user's orders but with the
    # new user, so to say. If there is at least one such pool order,
    # then pack all the orders inside a new customer order for the
    # new user.
    ####################################################################
    orders = reservations.map(&:order).compact.uniq

    if orders.presence
      p = orders.map(&:purpose).join('; ')
      customer_order = CustomerOrder.create!(user: user, purpose: p, title: p)
    end

    reservations.group_by(&:order).each_pair do |order, lines|
      if order
        new_order = Order.create!(user: user,
                                  inventory_pool: order.inventory_pool,
                                  customer_order: customer_order,
                                  state: order.state,
                                  purpose: order.purpose)
      end

      lines.each do |line|
        delegated_user = if user.delegation?
                           if user.delegated_users.include? line.delegated_user
                             line.delegated_user
                           else
                             user.delegator_user
                           end
                         end

        line.update_attributes!(user: user,
                                delegated_user: delegated_user,
                                order: new_order || nil)
      end
    end

    contract.update_attributes!(user: user)

  rescue => e
    log(e.message, :info, true)
    raise ActiveRecord::Rollback
  end
end

