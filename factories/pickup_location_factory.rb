FactoryBot.define do

  factory :pickup_location do
    inventory_pool
    name { Faker::Lorem.words(number: 3).join(' ').capitalize }
  end

end
