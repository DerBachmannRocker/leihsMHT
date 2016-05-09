FactoryGirl.define do
  factory :procurement_category, class: Procurement::Category do
    name { Faker::Lorem.sentence }

    trait :with_templates do
      after :create do |category|
        3.times do
          category.templates << FactoryGirl.create(:procurement_template)
        end
      end
    end
  end
end
