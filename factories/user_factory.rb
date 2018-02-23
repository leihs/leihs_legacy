FactoryGirl.define do

  factory :user do
    # make sure the login has at least 3 chars
    login do
      [Faker::Internet.user_name,
       Faker::Lorem.characters(8),
       (100..9999).to_a.sample]
        .join('_')
    end
    firstname { Faker::Name.first_name }
    lastname { Faker::Name.last_name }
    phone { Faker::PhoneNumber.phone_number.gsub(/\D/, '') }
    authentication_system do
      if AuthenticationSystem.first.blank?
        FactoryGirl.create(:authentication_system,
                           name: 'DatabaseAuthentication')
      else
        AuthenticationSystem.first
      end
    end
    org_id { Faker::Lorem.characters(32) }

    email do
      existing_emails = User.pluck :email
      r = Faker::Internet.email
      loop do
        r = Faker::Internet.email
        break unless existing_emails.include? r
      end
      r
    end

    badge_id { Faker::Lorem.characters(18) }
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    country { Faker::Address.country }
    zip { "#{country[0]}-#{Faker::Address.zip_code}".squish }
    language { Language.find_by_default(true) || LanguageFactory.create }
    delegator_user { nil }

    after(:create) do |user|
      unless user.delegation?
        FactoryGirl.create(:database_authentication,
                           user: user,
                           password: 'password')
      end
    end

    factory :delegation do
      delegator_user { FactoryGirl.create(:user) }
    end

    [:customer,
     :group_manager,
     :lending_manager,
     :inventory_manager].each do |role|
      factory role do
        transient do
          inventory_pool nil
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
        user.update_attributes! is_admin: true
      end
    end
  end
end
