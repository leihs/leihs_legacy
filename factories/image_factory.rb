FactoryGirl.define do

  trait :shared_attachment_attributes do
    filename { Faker::Lorem.word }
    content_type 'image/jpeg'
    size 1_000_000

    transient do
      filepath 'features/data/images/image1.jpg'
    end

    after(:build) do |image, evaluator|
      file = File.open(evaluator.filepath)
      image.content = Base64.encode64(file.read)
    end
  end

  factory :attachment do
    shared_attachment_attributes
  end

  factory :image do
    shared_attachment_attributes

    trait :another do
      transient do
        filepath 'features/data/images/image2.jpg'
      end
    end

    trait :with_thumbnail do
      after(:create) do |image, evaluator|
        create(:image,
               thumbnail: true,
               filepath: evaluator.filepath,
               parent_id: image.id)
      end
    end
  end
end
