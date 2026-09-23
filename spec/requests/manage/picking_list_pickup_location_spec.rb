require 'rails_helper'

describe 'Manage picking list pickup location column', type: :request do
  def login_as(user)
    token = SecureRandom.uuid
    token_hash = Digest::SHA256.hexdigest(token)
    auth_system = AuthenticationSystem.find_by(type: 'password') ||
      AuthenticationSystem.create!(id: 'password',
                                   name: 'leihs password',
                                   type: 'password')
    UserSession.create!(user: user,
                        authentication_system: auth_system,
                        token_hash: token_hash)
    cookies[Leihs::Constants::USER_SESSION_COOKIE_NAME] = token
  end

  def print_picking_list(reservation_ids)
    post "/manage/#{@inventory_pool.id}/reservations/print",
         params: { type: 'picking_list', ids: reservation_ids }
  end

  def header_labels
    doc = Nokogiri::HTML(response.body)
    doc.css('.picking_list thead tr:last-child th').map { |th| th.text.strip }
  end

  before :example do
    allow_any_instance_of(ActionController::Base)
      .to receive(:verify_authenticity_token).and_return(true)

    @inventory_pool = FactoryBot.create(
      :inventory_pool,
      enable_alternative_pickup_locations: true,
      default_pickup_location_name: 'Main Warehouse'
    )
    @manager = FactoryBot.create(:lending_manager,
                                  inventory_pool: @inventory_pool)
    @customer = FactoryBot.create(:customer, inventory_pool: @inventory_pool)
    @pickup_location = FactoryBot.create(:pickup_location,
                                          inventory_pool: @inventory_pool,
                                          name: 'Alt Desk')
    login_as(@manager)
  end

  it 'inserts pickup location after room/shelf when feature on' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      pickup_location: @pickup_location,
      start_date: Date.today,
      end_date: Date.tomorrow
    )

    print_picking_list([reservation.id])

    expect(response).to have_http_status(:ok)
    expect(header_labels).to eq [
      'Quantity',
      'Inventory Code',
      'Model',
      'available quantity x Room / Shelf',
      'Pickup location'
    ]
    expect(response.body).to include('Alt Desk')
  end

  it 'shows default_pickup_location_name when pickup_location_id is empty' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      start_date: Date.today,
      end_date: Date.tomorrow
    )

    print_picking_list([reservation.id])

    expect(response).to have_http_status(:ok)
    expect(header_labels).to include('Pickup location')
    pickup_cells = Nokogiri::HTML(response.body)
      .css('.picking_list tbody tr td.pickup_location')
      .map { |td| td.text.strip }
    expect(pickup_cells).to eq ['Main Warehouse']
  end

  it 'shows the alternative pickup location for a non-transportable model' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    item.model.update!(transportable: false)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      pickup_location: @pickup_location,
      start_date: Date.today,
      end_date: Date.tomorrow
    )

    print_picking_list([reservation.id])

    expect(response).to have_http_status(:ok)
    expect(header_labels).to include('Pickup location')
    pickup_cells = Nokogiri::HTML(response.body)
      .css('.picking_list tbody tr td.pickup_location')
      .map { |td| td.text.strip }
    expect(pickup_cells).to eq ['Alt Desk']
  end

  it 'keeps the original four columns when the feature is off' do
    @inventory_pool.update!(enable_alternative_pickup_locations: false)
    item = FactoryBot.create(:item, owner: @inventory_pool)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      start_date: Date.today,
      end_date: Date.tomorrow
    )

    print_picking_list([reservation.id])

    expect(response).to have_http_status(:ok)
    expect(header_labels).to eq [
      'Quantity',
      'Inventory Code',
      'Model',
      'available quantity x Room / Shelf'
    ]
    expect(response.body).not_to include('Pickup location')
  end

  it 'sorts unassigned rows by model name then room/shelf' do
    room_b = FactoryBot.create(:room, name: 'B-Room')
    room_a = FactoryBot.create(:room, name: 'A-Room')
    model = FactoryBot.create(:model)
    item_b = FactoryBot.create(:item, owner: @inventory_pool, model: model,
                                      room: room_b)
    item_a = FactoryBot.create(:item, owner: @inventory_pool, model: model,
                                      room: room_a)
    reservation_b = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: model,
      item: item_b,
      pickup_location: @pickup_location,
      start_date: Date.today,
      end_date: Date.tomorrow
    )
    reservation_a = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: model,
      item: item_a,
      pickup_location: @pickup_location,
      start_date: Date.today,
      end_date: Date.tomorrow
    )

    print_picking_list([reservation_b.id, reservation_a.id])

    expect(response).to have_http_status(:ok)
    doc = Nokogiri::HTML(response.body)
    rooms = doc.css('.picking_list tbody tr td.location').map { |td| td.text.strip }
    expect(rooms.first).to include('A-Room')
    expect(rooms.last).to include('B-Room')
  end
end
