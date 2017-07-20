FactoryGirl.define do

  factory :room do
    name { Faker::Lorem.words(3).join.capitalize }
    building
  end

end
