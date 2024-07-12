FactoryBot.define do

  factory :building do
    name { Faker::Lorem.words(number: 4).join(" ").capitalize }
    sequence(:code) do
      c = name.split(" ").map(&:first).join.upcase 
      "#{c}#{_1}"
    end
  end

end
