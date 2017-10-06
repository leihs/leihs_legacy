require 'rails_helper'

describe Reservation do
  before :example do
    @inventory_pool = FactoryGirl.create(:inventory_pool)
    @user = FactoryGirl.create(:customer, inventory_pool: @inventory_pool)
  end

  it 'auto deletes an empty order' do
    order = FactoryGirl.create(:order,
                               state: :submitted,
                               user: @user,
                               inventory_pool: @inventory_pool)
    reservation = FactoryGirl.create(:reservation,
                                     status: :submitted,
                                     user: @user,
                                     order: order,
                                     inventory_pool: @inventory_pool)
    order.reservations << reservation
    reservation.destroy
    expect { order.reload }.to raise_error ActiveRecord::RecordNotFound
  end

  it 'raises if user_id is not consistent with that of the order' do
    order = FactoryGirl.build(:order,
                              state: :submitted,
                              user: @user,
                              inventory_pool: @inventory_pool)
    expect do
      FactoryGirl.create(
        :item_line,
        order: order,
        user: FactoryGirl.create(:customer, inventory_pool: @inventory_pool),
        inventory_pool: @inventory_pool,
        status: :submitted)
    end.to raise_error /user_id between reservation and order is inconsistent/
  end

  it 'raises if inventory_pool_id is not consistent with that of the order' do
    order = FactoryGirl.build(:order,
                              state: :submitted,
                              user: @user,
                              inventory_pool: @inventory_pool)
    inventory_pool_2 = FactoryGirl.create(:inventory_pool)
    FactoryGirl.create(:access_right,
                       user: @user,
                       inventory_pool: inventory_pool_2,
                       role: :customer)
    expect do
      FactoryGirl.create(
        :item_line,
        order: order,
        user: @user,
        inventory_pool: inventory_pool_2,
        status: :submitted)
    end.to raise_error \
      /inventory_pool_id between reservation and order is inconsistent/
  end

  context ItemLine do
    context 'state consistency between orders and reservations' do
      it ':submitted -> :submitted' do
        %w(rejected approved).each do |state|
          order = FactoryGirl.build(:order,
                                    state: :submitted,
                                    user: @user,
                                    inventory_pool: @inventory_pool)
          expect do
            FactoryGirl.create(:item_line,
                               order: order,
                               user: @user,
                               inventory_pool: @inventory_pool,
                               status: state)
          end.to raise_error /state between item line and order is inconsistent/
        end
      end

      it ':rejected -> :rejected' do
        %w(submitted approved).each do |state|
          order = FactoryGirl.build(:order,
                                    state: :rejected,
                                    user: @user,
                                    inventory_pool: @inventory_pool)
          expect do
            FactoryGirl.create(:item_line,
                               order: order,
                               user: @user,
                               inventory_pool: @inventory_pool,
                               status: state)
          end.to raise_error /state between item line and order is inconsistent/
        end
      end

      it ':approved -> :approved, :signed, :closed' do
        %w(submitted rejected).each do |state|
          order = FactoryGirl.build(:order,
                                    state: :approved,
                                    user: @user,
                                    inventory_pool: @inventory_pool)
          expect do
            FactoryGirl.create(:item_line,
                               order: order,
                               user: @user,
                               inventory_pool: @inventory_pool,
                               status: state)
          end.to raise_error /state between item line and order is inconsistent/
        end
      end
    end
  end

  context OptionLine do
    it 'cannot belong to any order' do
      @inventory_pool = FactoryGirl.create(:inventory_pool)
      @user = FactoryGirl.create(:customer, inventory_pool: @inventory_pool)

      order = FactoryGirl.create(:order,
                                 state: 'approved',
                                 user: @user,
                                 inventory_pool: @inventory_pool)
      expect do
        FactoryGirl.create(:option_line,
                           order: order,
                           user: @user,
                           inventory_pool: @inventory_pool,
                           status: 'approved')
      end.to raise_error /option line cannot belong to an order/
    end
  end
end
