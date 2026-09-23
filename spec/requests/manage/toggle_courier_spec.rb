require 'rails_helper'

describe 'Manage::ReservationsController#toggle_courier', type: :request do
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

  before :example do
    # Mirror browser flow where jquery-ujs attaches the CSRF header;
    # request specs do not load the layout meta tag.
    allow_any_instance_of(ActionController::Base)
      .to receive(:verify_authenticity_token).and_return(true)

    @inventory_pool = FactoryBot.create(
      :inventory_pool,
      enable_alternative_pickup_locations: true
    )
    @manager = FactoryBot.create(:lending_manager,
                                  inventory_pool: @inventory_pool)
    @customer = FactoryBot.create(:customer, inventory_pool: @inventory_pool)
    @pickup_location = FactoryBot.create(:pickup_location,
                                          inventory_pool: @inventory_pool)
    login_as(@manager)
  end

  def toggle(reservation, direction:, handed:)
    post "/manage/#{@inventory_pool.id}/reservations/#{reservation.id}/toggle_courier",
         params: { direction: direction, handed: handed }
  end

  it 'sets sent_to_pickup_location fields without changing status' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      pickup_location: @pickup_location
    )

    toggle(reservation, direction: 'to_pickup', handed: true)

    expect(response).to have_http_status(:ok)
    reservation.reload
    expect(reservation.status).to eq :approved
    expect(reservation.contract_id).to be_nil
    expect(reservation.sent_to_pickup_location_at).to be_present
    expect(reservation.sent_to_pickup_location_by_user_id).to eq @manager.id

    toggle(reservation, direction: 'to_pickup', handed: false)
    reservation.reload
    expect(reservation.sent_to_pickup_location_at).to be_nil
  end

  it 'marks courier drop-off via sent_back without closing or freeing the item' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    contract = FactoryBot.create(:open_contract,
                                  inventory_pool: @inventory_pool,
                                  user: @customer,
                                  items: [item])
    reservation = contract.reservations.first
    reservation.update!(pickup_location: @pickup_location)

    toggle(reservation, direction: 'to_main', handed: true)

    expect(response).to have_http_status(:ok)
    reservation.reload
    # Dual-state: borrow shows returned via sent_back; returned_date stays nil
    # so before_save does not close the line and availability stays blocked.
    expect(reservation.status).to eq :signed
    expect(reservation.returned_date).to be_nil
    expect(reservation.sent_back_to_main_location_at).to be_present
    expect(reservation.sent_back_to_main_location_by_user_id).to eq @manager.id
  end

  it 'allows warehouse take_back after courier drop-off and then closes the line' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    contract = FactoryBot.create(:open_contract,
                                  inventory_pool: @inventory_pool,
                                  user: @customer,
                                  items: [item])
    reservation = contract.reservations.first
    reservation.update!(pickup_location: @pickup_location)

    toggle(reservation, direction: 'to_main', handed: true)
    expect(response).to have_http_status(:ok)
    reservation.reload
    expect(reservation.status).to eq :signed
    expect(reservation.returned_date).to be_nil

    post "/manage/#{@inventory_pool.id}/reservations/take_back",
         params: { ids: [reservation.id] }

    expect(response).to have_http_status(:ok)
    reservation.reload
    expect(reservation.status).to eq :closed
    expect(reservation.returned_date).to eq Time.zone.today
    expect(reservation.returned_to_user_id).to eq @manager.id
    expect(contract.reload.state).to eq 'closed'
  end

  it 'forbids courier toggle when alternative pickup locations are disabled' do
    @inventory_pool.update!(enable_alternative_pickup_locations: false)
    item = FactoryBot.create(:item, owner: @inventory_pool)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      pickup_location: @pickup_location
    )

    toggle(reservation, direction: 'to_pickup', handed: true)

    expect(response).to have_http_status(:forbidden)
    expect(reservation.reload.sent_to_pickup_location_at).to be_nil
  end

  it 'rejects to_pickup when reservation has no alternative pickup location' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item
    )

    toggle(reservation, direction: 'to_pickup', handed: true)

    expect(response).to have_http_status(:bad_request)
  end

  it 'rejects to_pickup when reservation is not approved' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    contract = FactoryBot.create(:open_contract,
                                  inventory_pool: @inventory_pool,
                                  user: @customer,
                                  items: [item])
    reservation = contract.reservations.first
    reservation.update!(pickup_location: @pickup_location)

    toggle(reservation, direction: 'to_pickup', handed: true)

    expect(response).to have_http_status(:bad_request)
    expect(reservation.reload.sent_to_pickup_location_at).to be_nil
  end

  it 'rejects to_main when reservation is not signed' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      pickup_location: @pickup_location
    )

    toggle(reservation, direction: 'to_main', handed: true)

    expect(response).to have_http_status(:bad_request)
    expect(reservation.reload.sent_back_to_main_location_at).to be_nil
  end

  it 'rejects to_main when reservation has no alternative pickup location' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    contract = FactoryBot.create(:open_contract,
                                  inventory_pool: @inventory_pool,
                                  user: @customer,
                                  items: [item])
    reservation = contract.reservations.first

    toggle(reservation, direction: 'to_main', handed: true)

    expect(response).to have_http_status(:bad_request)
    expect(reservation.reload.sent_back_to_main_location_at).to be_nil
  end

  it 'rejects courier toggle when the model is not transportable' do
    item = FactoryBot.create(:item, owner: @inventory_pool)
    item.model.update!(transportable: false)
    reservation = FactoryBot.create(
      :reservation,
      status: :approved,
      user: @customer,
      inventory_pool: @inventory_pool,
      model: item.model,
      item: item,
      pickup_location: @pickup_location
    )

    toggle(reservation, direction: 'to_pickup', handed: true)

    expect(response).to have_http_status(:bad_request)
    expect(reservation.reload.sent_to_pickup_location_at).to be_nil
  end
end
