FactoryBot.define do
  factory :pickup_location do
    inventory_pool
    name { Faker::Address.community }
    description { Faker::Lorem.sentence }
  end
end
