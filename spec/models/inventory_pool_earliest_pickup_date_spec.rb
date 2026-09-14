require 'rails_helper'

describe InventoryPool do
  before :example do
    @inventory_pool = FactoryBot.create(:inventory_pool)
    # Monday, so weekday math below isn't at the mercy of whenever specs run
    Timecop.travel(Date.new(2026, 9, 21))
  end

  after :example do
    Timecop.return
  end

  describe '#earliest_possible_pickup_date' do
    it 'is today when there is no advance period' do
      expect(@inventory_pool.earliest_possible_pickup_date(0)).to eq Time.zone.today
    end

    it 'counts today itself as the first advance day, and picks up once that many days have elapsed' do
      # Mon(1) Tue(2) Wed(3) elapse -> earliest pickup is the following day, Thursday
      expect(@inventory_pool.earliest_possible_pickup_date(3)).to eq Date.new(2026, 9, 24)
    end

    it 'skips weekends without counting them, but still lands on an open day' do
      Timecop.travel(Date.new(2026, 9, 18)) # Friday
      # Fri(1) -> Sat/Sun don't count -> Mon(2) -> Tue(3) elapse -> Wednesday
      expect(@inventory_pool.earliest_possible_pickup_date(3)).to eq Date.new(2026, 9, 23)
    end

    it 'keeps advancing past a closed day even once the advance count is met' do
      Timecop.travel(Date.new(2026, 9, 18)) # Friday
      # Fri(1) meets advance_days=1, but lands on Sat; keeps going to Sun (still
      # closed), lands open on Monday
      expect(@inventory_pool.earliest_possible_pickup_date(1)).to eq Date.new(2026, 9, 21)
    end
  end
end
