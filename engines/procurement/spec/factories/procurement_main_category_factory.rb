FactoryGirl.define do
  factory :procurement_main_category, class: Procurement::MainCategory do
    name { Faker::Lorem.sentence }

    after(:create) do |mc|
      Procurement::BudgetPeriod.all.each do |bp|
        FactoryGirl.create(
          :procurement_budget_limit, main_category: mc, budget_period: bp)
      end
    end

    trait :with_image do
      transient do
        filename 'image1.jpg'
        filepath { "#{Rails.root}/engines/procurement/spec/resources/#{filename}" }
        thumbnail_filename do
          "#{filename.split('.').first}_thumb.#{filename.split('.').second}"
        end
        thumbnail_filepath do
          "#{Rails.root}/engines/procurement/spec/resources/#{thumbnail_filename}"
        end
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
