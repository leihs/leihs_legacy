require 'rails_helper'
require 'rack/test'

# Regression test for Madek/Madek#946: proves the `redirect_to` heal
# specifically (as opposed to just not crashing), by checking that a write
# issued *after* the redirect actually persisted. Exercises the
# TransactionHealing concern through a real request (through
# Leihs::Middleware::Audit), which a plain controller spec would bypass.
describe 'TransactionHealing', type: :request do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  it 'redirect_to heals the connection after a locally-rescued DB error' do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    begin
      post '/redirect_then_query'
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    expect(last_response.status).to eq(302)
    expect(Language.find_by(name: 'Test Language After Redirect')).to be_present
  end
end
