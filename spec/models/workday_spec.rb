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
end
