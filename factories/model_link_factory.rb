FactoryBot.define do

  factory :model_link do
    model_group { FactoryBot.create :model_group }
    model { FactoryBot.create :model }
    quantity { 1 }
  end
end
