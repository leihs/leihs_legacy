FactoryGirl.define do

  factory :customer_order do
    user { FactoryGirl.create(:user) }
    purpose { Faker::Lorem.sentence }
  end

end
