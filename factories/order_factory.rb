FactoryGirl.define do

  factory :order do
    inventory_pool
    user { FactoryGirl.create(:customer, inventory_pool: inventory_pool) }
    purpose { Faker::Lorem.sentence }

    after(:build) do |order|
      co = create(:customer_order,
                  user: order.user,
                  purpose: order.purpose)
      order.customer_order_id = co.id
    end
  end

end
