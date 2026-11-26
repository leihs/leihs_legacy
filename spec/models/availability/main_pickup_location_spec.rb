require 'rails_helper'

describe Availability::Main do
  # anchored relative to today (with a week of margin) so the fixed
  # calendar dates below never drift into the past as time passes
  def mon
    Date.current.next_occurring(:monday) + 1.week
  end

  def fri
    mon + 4.days
  end

  def mon_after
    mon + 7.days
  end

  before :example do
    @inventory_pool = FactoryBot.create(:inventory_pool,
                                        transfer_buffer_before_pick_up: 2,
                                        transfer_buffer_after_drop_off: 2)
    @model = FactoryBot.create(:model_with_items, inventory_pool: @inventory_pool)
    @user = FactoryBot.create(:customer, inventory_pool: @inventory_pool)
  end

  def availability(model = @model)
    model.availability_in(@inventory_pool)
  end

  def available_on(date, model = @model)
    availability(model).maximum_available_in_period_for_groups(date, date, [])
  end

  context 'without a pickup_location (existing maintenance_period behavior)' do
    before :example do
      FactoryBot.create(:item_line,
                        inventory_pool: @inventory_pool,
                        user: @user,
                        model: @model,
                        status: :approved,
                        start_date: mon,
                        end_date: fri)
    end

    it 'is only blocked through end_date (maintenance_period defaults to 0)' do
      expect(available_on(mon)).to eq 2
      expect(available_on(fri)).to eq 2
      expect(available_on(mon_after)).to eq 3
    end
  end

  context 'with a pickup_location (transfer buffers apply)' do
    before :example do
      pickup_location = FactoryBot.create(:pickup_location,
                                          inventory_pool: @inventory_pool)
      FactoryBot.create(:item_line,
                        inventory_pool: @inventory_pool,
                        user: @user,
                        model: @model,
                        status: :approved,
                        start_date: mon,
                        end_date: fri,
                        pickup_location:)
    end

    it 'widens the blocked range backward and forward by orders-processing buffer days' do
      # before pick-up buffer of 2 processing days steps back over the
      # weekend, so the Thursday before is already blocked
      expect(available_on(mon - 4.days)).to eq 2
      expect(available_on(mon)).to eq 2
      expect(available_on(fri)).to eq 2

      # after drop-off buffer of 2 processing days steps forward over the
      # weekend, so it's still blocked the Monday after and only free again
      # two days later
      expect(available_on(mon_after)).to eq 2
      expect(available_on(mon_after + 2.days)).to eq 3
    end
  end

  context 'with an already-assigned item and a pickup_location (unavailable_from is today)' do
    it 'clamps the backward widening at today instead of recalculating the past' do
      pickup_location = FactoryBot.create(:pickup_location,
                                          inventory_pool: @inventory_pool)
      reservation = FactoryBot.create(:item_line, :with_assigned_item,
                                      inventory_pool: @inventory_pool,
                                      user: @user,
                                      status: :approved,
                                      start_date: mon,
                                      end_date: fri,
                                      pickup_location:)
      model = reservation.model

      expect { available_on(Time.zone.today, model) }.not_to raise_error
      expect(available_on(Time.zone.today, model)).to eq 0
    end
  end

  context 'with a holiday inside the after-drop-off buffer window' do
    it 'skips a holiday flagged as not orders_processing, widening the block further, like a weekend' do
      pickup_location = FactoryBot.create(:pickup_location,
                                          inventory_pool: @inventory_pool)
      wed = mon + 2.days
      thu = mon + 3.days
      @inventory_pool.holidays.create!(name: 'Holiday', start_date: thu,
                                       end_date: thu, orders_processing: false)
      FactoryBot.create(:item_line,
                        inventory_pool: @inventory_pool,
                        user: @user,
                        model: @model,
                        status: :approved,
                        start_date: mon,
                        end_date: wed,
                        pickup_location:)

      # without the holiday, buffer of 2 would land on the Friday (Thu,
      # Fri); the holiday on Thursday isn't counted, so it lands on the
      # Monday after (Fri, then skip the weekend, then Monday) instead
      expect(available_on(mon_after)).to eq 2
      expect(available_on(mon_after + 1.day)).to eq 3
    end
  end
end
