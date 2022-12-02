FactoryGirl.define do
  factory :supplier do
    name do
      "#{Faker::Lorem.words(number: 3).shuffle.join(' ')}_#{Faker::Lorem.characters(number: 16)}"
    end
  end
end
