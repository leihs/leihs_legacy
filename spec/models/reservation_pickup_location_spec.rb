require 'rails_helper'

describe 'Reservation pickup location serialization and courier flags' do
  before :example do
    @inventory_pool = FactoryBot.create(
      :inventory_pool,
      enable_alternative_pickup_locations: true,
      transfer_buffer_after_drop_off: 3,
      default_pickup_location_name: 'Main Location'
    )
    @user = FactoryBot.create(:customer, inventory_pool: @inventory_pool)
    @pickup_location = FactoryBot.create(:pickup_location,
                                          inventory_pool: @inventory_pool,
                                          name: 'Alt Desk')
  end

  it 'includes nested pickup_location in as_json_with_pickup_location when set' do
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @user,
      inventory_pool: @inventory_pool,
      pickup_location: @pickup_location
    )

    json = reservation.as_json_with_pickup_location
    expect(json['pickup_location_id']).to eq @pickup_location.id
    expect(json['pickup_location']).to eq(
      'id' => @pickup_location.id,
      'name' => 'Alt Desk'
    )
  end

  it 'omits nested pickup_location in as_json_with_pickup_location when not set' do
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @user,
      inventory_pool: @inventory_pool
    )

    expect(reservation.as_json_with_pickup_location).not_to have_key('pickup_location')
    expect(reservation.as_json).not_to have_key('pickup_location')
  end

  it 'is eligible for courier only with alt pickup and a transportable model' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @user,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      pickup_location: @pickup_location
    )

    expect(reservation.eligible_for_courier?).to be true

    reservation.update!(pickup_location: nil)
    expect(reservation.eligible_for_courier?).to be false

    reservation.update!(pickup_location: @pickup_location)
    item.model.update!(transportable: false)
    expect(reservation.reload.eligible_for_courier?).to be false
  end
end
