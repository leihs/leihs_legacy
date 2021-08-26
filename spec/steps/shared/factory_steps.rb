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

    step 'a customer for my inventory pool exists' do
      @inventory_pool = @current_user.inventory_pools.managed.first
      @customer = FactoryGirl.create(:customer, inventory_pool: @inventory_pool)
    end

    step 'there is a customer delegation for the current pool' do
      delegator = FactoryGirl.create(:customer,
                                     inventory_pool: @current_inventory_pool)
      @delegation = FactoryGirl.create(:customer,
                                       delegator_user_id: delegator.id,
                                       inventory_pool: @current_inventory_pool)
    end

    step 'a submitted order for the customer exists' do
      @order = FactoryGirl.create(:order,
                                  inventory_pool: @current_inventory_pool,
                                  state: :submitted)
      FactoryGirl.create(:reservation,
                         inventory_pool: @order.inventory_pool,
                         user: @order.user,
                         status: :submitted,
                         order: @order)
    end

    step 'an item owned by my inventory pool exists' do
      @item = FactoryGirl.create(:item, owner: @inventory_pool)
    end

    step 'a license owned by my inventory pool exists' do
      @license = FactoryGirl.create(:license, owner: @inventory_pool)
    end

    step 'there exists a software' do
      @software = FactoryGirl.create(:software)
    end

    step 'there exists a model' do
      @model = FactoryGirl.create(:model)
    end

    step 'there is a model' do
      step 'there exists a model'
    end

    step 'a model exists' do
      step 'there exists a model'
    end

    step 'the item is borrowable' do
      @item.update_attributes!(is_borrowable: true)
    end

    step 'the item is retired' do
      @item.update_attributes!(retired: true,
                               retired_reason: Faker::Lorem.sentence)
    end

    step 'there is a borrowable item for the model' do
      FactoryGirl.create(:item,
                         is_borrowable: true,
                         model: @model)
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
