FactoryGirl.define do

  factory :group, class: EntitlementGroup do
    name { Faker::Name.name }
    association :inventory_pool
  end
end
