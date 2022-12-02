FactoryGirl.define do

  factory :category do
    name Faker::Lorem.words(number: 3).join.capitalize
  end

end
