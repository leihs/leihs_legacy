FactoryGirl.define do
  factory :procurement_setting, class: Procurement::Setting do
    contact_url { Faker::Internet.url }
  end
end
