FactoryGirl.define do

  factory :group, class: EntitlementGroup do
    name { Faker::Name.name }
    inventory_pool
  end
end
