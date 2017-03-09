FactoryGirl.define do
  factory :partition do
    association :model
    association :group
    association :inventory_pool
    quantity 1
  end
end
