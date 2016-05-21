FactoryGirl.define do
  factory :procurement_main_category, class: Procurement::MainCategory do
    name { Faker::Lorem.sentence }
  end
end
