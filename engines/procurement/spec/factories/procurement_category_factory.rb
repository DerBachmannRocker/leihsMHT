FactoryGirl.define do
  factory :procurement_category, class: Procurement::Category do
    name { Faker::Lorem.sentence }

    # association :parent, factory: :procurement_category
    parent { nil }

    trait :as_leaf do
      before :create do |category|
        category.parent = FactoryGirl.create(:procurement_category, parent: nil)
      end
    end

    trait :with_templates do
      before :create do |category|
        category.parent = FactoryGirl.create(:procurement_category, parent: nil)
      end
      after :create do |category|
        3.times do
          category.templates << FactoryGirl.create(:procurement_template)
        end
      end
    end
  end
end
