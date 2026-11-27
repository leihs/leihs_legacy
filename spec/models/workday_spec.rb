require 'rails_helper'

describe Workday do
  before :example do
    @inventory_pool = FactoryBot.create(:inventory_pool)
    @workday = @inventory_pool.workday
  end

  describe '#orders_processing_day?' do
    it 'returns the per-weekday orders_processing flag' do
      @workday.update!(monday: false, monday_orders_processing: false,
                       saturday_orders_processing: true)

      monday = Date.new(2026, 9, 14)
      saturday = Date.new(2026, 9, 19)

      expect(monday.wday).to eq 1
      expect(saturday.wday).to eq 6
      expect(@workday.orders_processing_day?(monday)).to eq false
      expect(@workday.orders_processing_day?(saturday)).to eq true
    end
  end

  describe '#reached_max_visits' do
    before :example do
      @date = @inventory_pool.next_open_date(Time.zone.today + 1.day)
      @workday.update!(max_visits: { @date.wday.to_s => '2' })
      @user = FactoryBot.create(:customer, inventory_pool: @inventory_pool)
      order = FactoryBot.create(:order,
                                state: :submitted,
                                user: @user,
                                inventory_pool: @inventory_pool)
      FactoryBot.create(:item_line,
                        status: :submitted,
                        order: order,
                        user: @user,
                        inventory_pool: @inventory_pool,
                        start_date: @date,
                        end_date: @date)
    end

    def create_approved_reservation(user)
      FactoryBot.create(:item_line,
                        status: :approved,
                        user: user,
                        inventory_pool: @inventory_pool,
                        start_date: @date,
                        end_date: @date)
    end

    it 'counts submitted and approved of same user as one visit' do
      create_approved_reservation(@user)
      expect(@workday.reload.reached_max_visits).not_to include @date
    end

    it 'counts visits of different users separately' do
      create_approved_reservation(
        FactoryBot.create(:customer, inventory_pool: @inventory_pool)
      )
      expect(@workday.reload.reached_max_visits).to include @date
    end
  end
end
