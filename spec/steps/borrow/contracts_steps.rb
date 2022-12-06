require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module ContractsSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step "I visit a contract of user's delegation" do
        @delegation = FactoryBot.create(:delegation)
        @delegation.delegated_users << @customer
        pool = FactoryBot.create(:inventory_pool)
        FactoryBot.create(:access_right,
                           user: @delegation,
                           inventory_pool: pool)
        FactoryBot.create(:access_right,
                           user: @customer,
                           inventory_pool: pool)
        @contract = FactoryBot.create(:open_contract,
                                       user: @delegation,
                                       contact_person: @customer,
                                       inventory_pool: pool)
        visit "/borrow/user/contracts/#{@contract.id}"
      end

      step "I visit a contract of not user's delegation" do
        @delegation = FactoryBot.create(:delegation)
        contact_person = FactoryBot.create(:user)
        @delegation.delegated_users << contact_person
        pool = FactoryBot.create(:inventory_pool)
        FactoryBot.create(:access_right,
                           user: @delegation,
                           inventory_pool: pool)
        FactoryBot.create(:access_right,
                           user: @customer,
                           inventory_pool: pool)
        FactoryBot.create(:access_right,
                           user: contact_person,
                           inventory_pool: pool)
        @contract = FactoryBot.create(:open_contract,
                                       user: @delegation,
                                       contact_person: contact_person,
                                       inventory_pool: pool)
        visit "/borrow/user/contracts/#{@contract.id}"
      end

      step "I see the contract" do
        expect(page).to have_content @contract.compact_id
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::ContractsSteps, borrow_contracts: true
end
