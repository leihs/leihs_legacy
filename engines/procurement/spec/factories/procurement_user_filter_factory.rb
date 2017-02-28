FactoryGirl.define do
  factory :procurement_user_filter, class: Procurement::UserFilter do
    association :user
    filter do
      { priorities: ['high'] }
    end
  end
end
