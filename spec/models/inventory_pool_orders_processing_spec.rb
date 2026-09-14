require 'rails_helper'

describe InventoryPool do
  before :example do
    @inventory_pool = FactoryBot.create(:inventory_pool)
    # weekend closed & not orders-processing (matches DB defaults), Mon-Fri open & processing
  end

  describe '#orders_processing?' do
    it 'is false on non-processing weekdays and true on processing weekdays' do
      saturday = Date.new(2026, 9, 19) # closed, not processing by default
      monday = Date.new(2026, 9, 21) # open, processing by default

      expect(@inventory_pool.orders_processing?(saturday)).to eq false
      expect(@inventory_pool.orders_processing?(monday)).to eq true
    end

    it 'is false on a holiday flagged as not orders_processing, even on an open weekday' do
      monday = Date.new(2026, 9, 21)
      @inventory_pool.holidays.create!(name: 'Holiday', start_date: monday,
                                       end_date: monday, orders_processing: false)

      expect(@inventory_pool.orders_processing?(monday)).to eq false
    end
  end

  describe '#step_orders_processing_days' do
    it 'is a no-op for n <= 0' do
      friday = Date.new(2026, 9, 18)

      expect(@inventory_pool.step_orders_processing_days(friday, 0)).to eq friday
      expect(@inventory_pool.step_orders_processing_days(friday, -1)).to eq friday
    end

    it 'never counts the start date, and skips over the weekend without counting it' do
      friday = Date.new(2026, 9, 18)

      # stepping forward 1 processing day from Friday skips Sat/Sun, lands on Monday
      expect(@inventory_pool.step_orders_processing_days(friday, 1, step: :+))
        .to eq Date.new(2026, 9, 21)

      # stepping backward 1 processing day from Monday skips Sun/Sat, lands on Friday
      monday = Date.new(2026, 9, 21)
      expect(@inventory_pool.step_orders_processing_days(monday, 1, step: :-))
        .to eq Date.new(2026, 9, 18)
    end

    it 'counts multiple processing days across a weekend' do
      thursday = Date.new(2026, 9, 17)

      # Thu -> Fri (1) -> skip Sat/Sun -> Mon (2)
      expect(@inventory_pool.step_orders_processing_days(thursday, 2, step: :+))
        .to eq Date.new(2026, 9, 21)
    end
  end
end
