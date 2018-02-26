FactoryGirl.define do
  factory :entitlement do
    association :model
    association :entitlement_group, factory: :group
    quantity 1
  end
end
