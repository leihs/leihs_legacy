FactoryBot.define do

  factory :template do
    name { Faker::Name.name }
    type { 'Template' }

    after(:build) do |template|
      3.times do
        template.model_links << FactoryBot.build(:model_link)
      end
    end
  end
end
