FactoryBot.define do

  factory :authentication_system_user do
    association :user
    authentication_system_id { 'password' }
  end
end
