FactoryBot.define do
  factory :account do
    user
    uuid { SecureRandom.uuid }
    status { "active" }
  end

  factory :account_record, class: 'Account' do
    user
    uuid { SecureRandom.uuid }
    status { "active" }
  end
end
