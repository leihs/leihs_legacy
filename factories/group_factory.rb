FactoryBot.define do
  factory :simple_group, class: Group do
    name { Faker::Lorem.word }
  end
end
