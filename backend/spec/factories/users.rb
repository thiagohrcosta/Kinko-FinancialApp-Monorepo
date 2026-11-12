FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "SecurePassword123!" }
    password_confirmation { password }
    full_name { "Test User" }
    document_number { "12345678901" }
    phone_number { "+5511999999999" }
    address_street { "Main Street" }
    address_number { "100" }
    address_complement { "Apt 10" }
    address_neighborhood { "Downtown" }
    address_city { "Sao Paulo" }
    address_state { "SP" }
    address_zip_code { "01000-000" }
    address_country { "BR" }

    trait :californian do
      address_country { "US" }
      address_state { "CA" }
      address_city { "San Francisco" }
      address_zip_code { "94105" }
    end

    trait :business do
      user_type { "business" }
      business_name { "Acme Motors" }
      business_sector { "automotive" }
    end
  end
end
