FactoryGirl.define do
  factory :property do
    association :model
    key { Faker::Lorem.word }
    value { Faker::Lorem.word }
  end
end
