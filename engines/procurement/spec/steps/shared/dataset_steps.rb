module DatasetSteps

  step 'the basic dataset is ready' do
    step 'a procurement admin exists'
    step 'the current budget period exist'
    step 'there exists a main category'
    step 'there exists a sub category'
    step 'there exist 3 requesters'
  end

  ######################################################

  step 'a procurement admin exists' do
    Procurement::Access.admins.exists? \
      || FactoryGirl.create(:procurement_access, :admin)
  end

  step 'there exist :count requesters' do |count|
    count.to_i.times do
      FactoryGirl.create(:procurement_access, :requester)
    end
  end

  step 'there exists a :level category' do |level|
    @category = case level
                when 'main'
                  Procurement::MainCategory.first || \
                  FactoryGirl.create(:procurement_main_category)
                when 'sub'
                  Procurement::Category.first || \
                  FactoryGirl.create(:procurement_category)
                else
                  raise
                end
  end
  step 'a main category exists' do
    step 'there exists a main category'
  end
  step 'a category exists' do
    step 'there exists a sub category'
  end

  step 'the current budget period exist' do
    @budget_period = FactoryGirl.create(:procurement_budget_period)
  end

end
