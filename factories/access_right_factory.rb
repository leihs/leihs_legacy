FactoryGirl.define do

  factory :suspension do
  end

  factory :direct_access_right do
    user
    inventory_pool
    role {[:customer, :group_manager, :lending_manager, :inventory_manager].sample}
  end

  factory :access_right do
    role { :customer }
    user
    inventory_pool

    transient do
      suspended_until nil
      suspended_reason nil
    end

    after :create do |ac, trans|
      if trans.suspended_until
        FactoryGirl.create :suspension,
                           suspended_until: trans.suspended_until,
                           suspended_reason: trans.suspended_reason,
                           inventory_pool_id: ac.inventory_pool_id,
                           user_id: ac.user_id
      end
    end

  end

end
