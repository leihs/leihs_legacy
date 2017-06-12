module Spec
  module FactorySteps
    step 'there exists an inventory pool' do
      @inventory_pool = FactoryGirl.create(:inventory_pool)
    end

    step 'there exists an active inventory pool' do
      @active_inventory_pool = FactoryGirl.create(:inventory_pool,
                                                  is_active: true)
    end

    step 'there exists an inactive inventory pool' do
      @inactive_inventory_pool = FactoryGirl.create(:inventory_pool,
                                                    is_active: false)
    end

    step 'there exists a category' do
      @category = FactoryGirl.create(:category)
    end
  end
end
