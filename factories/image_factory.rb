FactoryGirl.define do

  trait :shared_attachment_attributes do
    filename { Faker::Lorem.word }
    content_type 'image/jpeg'

    transient do
      filepath 'features/data/images/image1.jpg'
    end

    after(:build) do |image, evaluator|
      file = File.open(evaluator.filepath)
      data = StringIO.new(file.read)
      data.class.class_eval { attr_accessor :original_filename, :content_type }
      data.original_filename = image.filename
      data.content_type = image.content_type
      image.file = data
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
  end
end
