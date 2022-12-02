FactoryGirl.define do

  factory :room do
    name { Faker::Lorem.words(number: 3).join.capitalize }
    building
  end

end
