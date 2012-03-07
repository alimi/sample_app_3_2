FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Person #{n}" }
    sequence(:email) { |n| "person_#{n}@examlple.com" }
    password "foobar"

    factory :admin do
      admin true
    end
  end
end
