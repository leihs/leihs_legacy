FactoryGirl.define do
  factory :entitlement do
    association :model
    association :entitlement_group, factory: :group
    association :inventory_pool
    quantity 1
  end
end
