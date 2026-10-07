require 'rails_helper'

RSpec.describe 'manage pagination header', type: :request do
  def sign_in(user)
    token = SecureRandom.uuid
    real_now = ActiveRecord::Base.connection.select_value('SELECT now()')
    UserSession.create!(
      user: user,
      authentication_system: AuthenticationSystem.find_by!(id: 'password'),
      token_hash: Digest::SHA256.hexdigest(token),
      created_at: real_now
    )
    cookies[Leihs::Constants::USER_SESSION_COOKIE_NAME] = token
  end

  def pagination
    JSON.parse(response.headers['X-Pagination'])
  end

  let(:pool) { FactoryBot.create(:inventory_pool) }
  let(:manager) { FactoryBot.create(:lending_manager, inventory_pool: pool) }

  before { sign_in(manager) }

  example 'contracts count unless disable_total_count is set' do
    contract = FactoryBot.create(:closed_contract, inventory_pool: pool)
    params = { global_contracts_search: true, status: %w[open closed] }

    get "/manage/#{pool.id}/contracts.json", params: params

    expect(response).to have_http_status(:ok)
    expect(pagination['total_count']).to eq 1
    expect(response.body).to include(contract.id)

    get "/manage/#{pool.id}/contracts.json",
        params: params.merge(disable_total_count: true)

    expect(response).to have_http_status(:ok)
    expect(pagination['total_count']).to be_nil
    expect(response.body).to include(contract.id)
  end

  example 'items count unless disable_total_count is set' do
    item = FactoryBot.create(:item, inventory_pool: pool, owner: pool)

    get "/manage/#{pool.id}/items.json"

    expect(response).to have_http_status(:ok)
    expect(pagination['total_count']).to eq 1
    expect(response.body).to include(item.id)

    get "/manage/#{pool.id}/items.json", params: { disable_total_count: true }

    expect(response).to have_http_status(:ok)
    expect(pagination['total_count']).to be_nil
    expect(response.body).to include(item.id)
  end
end
