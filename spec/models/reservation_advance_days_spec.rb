require 'rails_helper'

describe Reservation do
  before :example do
    @inventory_pool = FactoryBot.create(:inventory_pool,
                                        borrow_reservation_advance_days: 1,
                                        transfer_buffer_before_pick_up: 3)
    @user = FactoryBot.create(:customer, inventory_pool: @inventory_pool)
    Timecop.travel(Date.new(2026, 9, 21)) # Monday
  end

  after :example do
    Timecop.return
  end

  def build_reservation(start_date:, pickup_location: nil)
    FactoryBot.build(:item_line,
                     inventory_pool: @inventory_pool,
                     user: @user,
                     status: :unsubmitted,
                     start_date:,
                     end_date: start_date,
                     pickup_location:)
  end

  describe '#start_date_within_advance_days_period?' do
    context 'without a pickup_location' do
      it 'only considers borrow_reservation_advance_days (unchanged behavior)' do
        # advance_days=1: today (Mon) violates, tomorrow (Tue) is fine, even
        # though transfer_buffer_before_pick_up would demand more
        expect(build_reservation(start_date: Date.new(2026, 9, 21))
          .start_date_within_advance_days_period?).to eq true
        expect(build_reservation(start_date: Date.new(2026, 9, 22))
          .start_date_within_advance_days_period?).to eq false
      end
    end

    context 'with a pickup_location' do
      it 'uses the larger of borrow_reservation_advance_days and transfer_buffer_before_pick_up' do
        pickup_location = FactoryBot.create(:pickup_location,
                                            inventory_pool: @inventory_pool)

        # transfer_buffer_before_pick_up=3 dominates: Mon/Tue/Wed elapse,
        # earliest pickup is Thursday 9/24
        expect(build_reservation(start_date: Date.new(2026, 9, 23), pickup_location:)
          .start_date_within_advance_days_period?).to eq true
        expect(build_reservation(start_date: Date.new(2026, 9, 24), pickup_location:)
          .start_date_within_advance_days_period?).to eq false
      end
    end
  end
end
