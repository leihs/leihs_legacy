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

    step 'there exists a software' do
      @software = FactoryGirl.create(:software)
    end

    step 'there exists a model' do
      @model = FactoryGirl.create(:model)
    end

    step 'there exists a category' do
      @category = FactoryGirl.create(:category)
    end

    step 'there exists a user' do
      @user = FactoryGirl.create(:user)
    end

    step 'there exists a room' do
      @room = FactoryGirl.create(:room)
    end

    step 'there exists a building' do
      @building = FactoryGirl.create(:building)
    end

    step 'there exists a building :name' do |name|
      @building = FactoryGirl.create(:building, name: name)
    end
  end
end
