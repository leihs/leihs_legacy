FactoryBot.define do
  factory :entitlement_group do
    name { Faker::Lorem.word }
    association :inventory_pool
  end
end
