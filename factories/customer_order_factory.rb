FactoryBot.define do

  factory :customer_order do
    user { FactoryBot.create(:user) }
    purpose { Faker::Lorem.sentence }
    title { purpose }
  end

end
