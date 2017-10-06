FactoryGirl.define do

  factory :order do
    inventory_pool
    user { FactoryGirl.create(:customer, inventory_pool: inventory_pool) }
    purpose { Faker::Lorem.sentence }
  end

end
