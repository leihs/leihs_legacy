require 'rails_helper'

describe MailTemplate do

  before :example do
    @inventory_pool = FactoryBot.create(:inventory_pool,
                                        default_pickup_location_name: 'Main Location')
  end

  describe '.liquid_variables_for_order' do
    it "uses the reservation's pickup location name when set" do
      pickup_location = FactoryBot.create(:pickup_location,
                                          inventory_pool: @inventory_pool,
                                          name: 'Alt Location')
      order = FactoryBot.create(:order,
                                state: :submitted,
                                inventory_pool: @inventory_pool)
      reservation = FactoryBot.create(:item_line,
                                      status: :submitted,
                                      inventory_pool: @inventory_pool,
                                      user: order.user,
                                      order: order,
                                      pickup_location: pickup_location)
      order.reservations << reservation

      variables = MailTemplate.liquid_variables_for_order(order)

      expect(variables['reservations'].first['pickup_location_name'])
        .to eq('Alt Location')
    end

    it "falls back to the inventory pool's default pickup location name" do
      order = FactoryBot.create(:order,
                                state: :submitted,
                                inventory_pool: @inventory_pool)
      reservation = FactoryBot.create(:item_line,
                                      status: :submitted,
                                      inventory_pool: @inventory_pool,
                                      user: order.user,
                                      order: order,
                                      pickup_location: nil)
      order.reservations << reservation

      variables = MailTemplate.liquid_variables_for_order(order)

      expect(variables['reservations'].first['pickup_location_name'])
        .to eq('Main Location')
    end
  end

  describe '.liquid_variables_for_user' do
    it "uses the reservation's pickup location name when set" do
      pickup_location = FactoryBot.create(:pickup_location,
                                          inventory_pool: @inventory_pool,
                                          name: 'Alt Location')
      reservation = FactoryBot.create(:item_line,
                                      :with_assigned_item,
                                      inventory_pool: @inventory_pool,
                                      pickup_location: pickup_location)

      variables = MailTemplate.liquid_variables_for_user(
        reservation.user, @inventory_pool, [reservation])

      expect(variables['reservations'].first['pickup_location_name'])
        .to eq('Alt Location')
    end

    it "falls back to the inventory pool's default pickup location name" do
      reservation = FactoryBot.create(:item_line,
                                      :with_assigned_item,
                                      inventory_pool: @inventory_pool,
                                      pickup_location: nil)

      variables = MailTemplate.liquid_variables_for_user(
        reservation.user, @inventory_pool, [reservation])

      expect(variables['reservations'].first['pickup_location_name'])
        .to eq('Main Location')
    end
  end
end
