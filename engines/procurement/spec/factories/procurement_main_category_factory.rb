FactoryGirl.define do
  factory :procurement_main_category, class: Procurement::MainCategory do
    name { Faker::Lorem.sentence }

    trait :with_image do
      transient do
        filepath "#{Rails.root}/engines/procurement/spec/resources/image1.jpg"
        thumbnail_filepath \
          "#{Rails.root}/engines/procurement/spec/resources/image1_thumb.jpg"
      end

      after(:create) do |main_category, evaluator|
        FactoryGirl.create(:procurement_image,
                           main_category: main_category,
                           filepath: evaluator.filepath,
                           thumbnail_filepath: evaluator.thumbnail_filepath)
      end
    end
  end
end
