FactoryGirl.define do

  factory :inventory_pool do |i|
    name { Faker::Lorem.words(number: 4).join.capitalize }
    description { Faker::Lorem.sentence }
    contact_details { Faker::Lorem.sentence }
    contract_description { name }
    email { Faker::Internet.email }
    contract_url { email }
    shortname { Faker::Lorem.characters(number: 6).upcase }
    automatic_suspension { false }

    after(:create) do |inventory_pool|
      MailTemplate.where(is_template_template: true).each do |mt|
        MailTemplate.create! \
          mt.attributes
          .reject { |k, _| k == 'id' }
          .merge(is_template_template: false,
                 inventory_pool_id: inventory_pool.id)
      end
    end

    factory :inventory_pool_with_customers do
      after(:create) do |inventory_pool, evaluator|
        rand(3..6).times do
          user = FactoryGirl.create :user
          user.access_rights.create(inventory_pool: inventory_pool,
                                    role: :customer)
        end
      end
    end
  end

end
