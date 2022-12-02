FactoryGirl.define do

  factory :building do
    name { Faker::Lorem.words(number: 3).join.capitalize }
    code { Faker::Lorem.words(number: 3).join[0..2] }
  end

end
