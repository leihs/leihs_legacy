FactoryBot.define do

  factory :room do
    name { Faker::Lorem.words(number: 4).join(" ").capitalize }
    building
  end

end
