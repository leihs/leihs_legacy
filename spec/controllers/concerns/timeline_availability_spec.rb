require 'rails_helper'

describe TimelineAvailability do
  let(:harness) { Class.new { include TimelineAvailability }.new }

  describe '#add_timeline_dates!' do
    it 'leaves non-pickup-location reservations untouched, widens pickup-location ones' do
      inventory_pool = FactoryBot.create(:inventory_pool,
                                         transfer_buffer_before_pick_up: 2,
                                         transfer_buffer_after_drop_off: 2)
      plain = { 'pickup_location_id' => nil,
               'start_date' => Date.new(2026, 9, 21),
               'end_date' => Date.new(2026, 9, 23) }
      pul = { 'pickup_location_id' => SecureRandom.uuid,
             'start_date' => Date.new(2026, 9, 21),
             'end_date' => Date.new(2026, 9, 23) }
      reservations = [plain, pul]

      harness.send(:add_timeline_dates!, reservations, inventory_pool)

      expect(plain['timeline_start_date']).to eq Date.new(2026, 9, 21)
      expect(plain['timeline_end_date']).to eq Date.new(2026, 9, 23)

      # before_pick_up=2 steps back over the weekend: Thu(1) Fri... wait
      # backward from Monday skips Sun/Sat, counts Fri(1) Thu(2) -> 9/17
      expect(pul['timeline_start_date']).to eq Date.new(2026, 9, 17)
      # after_drop_off=2 steps forward from Wednesday: Thu(1) Fri(2) -> 9/25
      expect(pul['timeline_end_date']).to eq Date.new(2026, 9, 25)
    end
  end
end
