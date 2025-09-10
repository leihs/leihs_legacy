FactoryBot.define do
  factory :entitlement_group do
    name { Faker::Lorem.word }
    association :inventory_pool
  end

  factory :group, class: EntitlementGroup do
    name { Faker::Name.name }
    association :inventory_pool
  end
end
