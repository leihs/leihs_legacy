FactoryGirl.define do
  factory :procurement_image, class: Procurement::Image do
    transient do
      filepath "#{Rails.root}/engines/procurement/spec/resources/image1.jpg"
      thumbnail_filepath \
        "#{Rails.root}/engines/procurement/spec/resources/image1_thumb.jpg"
      file { File.open(filepath) }
    end

    association :main_category, factory: :procurement_main_category

    filename { File.basename(filepath) }
    content { Base64.encode64(file.read) }
    size { file.size }
    content_type { Procurement::FileUtilities.content_type(filepath) }

    parent_id nil

    after(:create) do |image, evaluator| # create thumbnail
      unless image.parent_id
        FactoryGirl.create(:procurement_image,
                           main_category: image.main_category,
                           parent_id: image.id,
                           filepath: evaluator.thumbnail_filepath)
      end
    end
  end
end
