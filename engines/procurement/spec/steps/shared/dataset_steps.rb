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
                  Procurement::Category.main.first || \
                  FactoryGirl.create(:procurement_category, parent: nil)
                when 'sub'
                  Procurement::Category.leafs.first || \
                  begin
                    parent = FactoryGirl.create(:procurement_category, parent: nil)
                    FactoryGirl.create(:procurement_category, parent: parent)
                  end
                else
                  raise
                end
  end

  step 'the current budget period exist' do
    @budget_period = FactoryGirl.create(:procurement_budget_period)
  end

end
