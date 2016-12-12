FactoryGirl.define do

  sequence :version

  trait :shared_model_software_attributes do
    manufacturer { Faker::Company.name }
    product do
      r = Faker::Commerce.product_name
      loop do
        r = Faker::Commerce.product_name
        break unless (Model.find_by_product(r))
      end
      r
    end
    version
  end

  factory :model do
    shared_model_software_attributes

    description { Faker::Lorem.sentence }
    internal_description { Faker::Lorem.sentence }
    maintenance_period { rand(4) }
    is_package false
    technical_detail { Faker::Lorem.sentence }
    hand_over_note { Faker::Lorem.sentence }

    factory :model_with_items do
      transient do
        inventory_pool { FactoryGirl.create :inventory_pool }
        is_borrowable true
      end
      after(:create) do |model, evaluator|
        3.times do
          model.items << \
            FactoryGirl.create(:item,
                               is_borrowable: evaluator.is_borrowable,
                               inventory_pool: evaluator.inventory_pool)
        end
      end
    end

  end

  factory :software, traits: [:shared_model_software_attributes]

end
