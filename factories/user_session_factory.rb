FactoryGirl.define do
  factory :user_session do
    token_hash { Digest::SHA256.hexdigest SecureRandom.uuid }
  end
end
