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

    step 'there is a customer for the current pool' do
      @user = FactoryGirl.create(:customer,
                                 inventory_pool: @current_inventory_pool)
    end

    step 'there is a customer delegation for the current pool' do
      delegator = FactoryGirl.create(:customer,
                                     inventory_pool: @current_inventory_pool)
      @delegation = FactoryGirl.create(:customer,
                                       delegator_user_id: delegator.id,
                                       inventory_pool: @current_inventory_pool)
    end

    step 'there exists a software' do
      @software = FactoryGirl.create(:software)
    end

    step 'there exists a model' do
      @model = FactoryGirl.create(:model)
    end

    step 'there exists a model with items' do
      @model = FactoryGirl.create(:model)
      3.times do
        FactoryGirl.create(:item, model: @model)
      end
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
