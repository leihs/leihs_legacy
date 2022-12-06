FactoryBot.define do

  factory :user do
    login { Faker::Lorem.characters(number: 12) }
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    phone { Faker::PhoneNumber.phone_number.gsub(/\D/, '') }
    org_id { Faker::Lorem.characters(number: 32) }

    email do
      existing_emails = User.pluck :email
      r = Faker::Internet.email
      loop do
        r = Faker::Internet.email
        break unless existing_emails.include? r
      end
      r
    end

    badge_id { Faker::Lorem.characters(number: 18) }
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    country { Faker::Address.country }
    zip { "#{country[0]}-#{Faker::Address.zip_code}".squish }
    language do
      Language.find_by_default(true) || create(:language, locale: 'en-GB')
    end
    delegator_user { nil }
    organization { Faker::Lorem.characters(number: 8) }

    after(:create) do |user|
      unless user.delegation?
        create :authentication_system_user, user: user
      end
    end

    factory :delegation do
      delegator_user { FactoryBot.create(:user) }
    end

    [:customer,
     :group_manager,
     :lending_manager,
     :inventory_manager].each do |role|
      factory role do
        transient do
          inventory_pool { nil }
        end

        after(:create) do |user, evaluator|
          create(:access_right,
                 user: user,
                 inventory_pool: evaluator.inventory_pool,
                 role: role)
        end
      end
    end

    factory :admin do
      after(:create) do |user, evaluator|
        user.update_attributes! is_admin: true, admin_protected: true
      end
    end
  end
end
