require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module CreateSoftwareLicenseSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I navigate to the create software license page' do
        visit manage_new_item_path(@current_inventory_pool, type: :license)
      end

      step 'the possible select values for :field are as follows:' \
        do |field, table|
        within find('.field', text: _(field)) do
          options = all('select option').map(&:text)
          expect(table.raw.flatten).to be == options
        end
      end

      step 'the possible radio button values for :field are as follows:' \
        do |field, table|
        within find('.field', text: _(field)) do
          table.raw.flatten.each do |val|
            within('label', text: val) do
              find("input[type='radio']")
            end
          end
        end
      end

      step 'the possible checkbox values for :field are as follows:' \
        do |field, table|
        within find('.field', text: _(field)) do
          table.raw.flatten.each do |val|
            within('label', text: val) do
              find("input[type='checkbox']")
            end
          end
        end
      end

      step 'for :field one can select a date' do |field|
        within find('.field', text: _(field)) do
          find('input')
        end
      end

      step 'for :field one can enter some value' do |field|
        within find('.field', text: _(field)) do
          find("input[type='text'],textarea")
        end
      end

      step 'for :field one can choose a value via autocomplete' do |field|
        within find('.field', text: _(field)) do
          find('input')
        end
      end

      step 'the default radio button for :field is :value' do |field, value|
        within find('.field', text: _(field)) do
          within('label', text: _(value)) do
            expect(find('input').checked?).to eq(true)
          end
        end
      end

      step 'there is a software' do
        @software = FactoryGirl.create(:software)
      end

      step 'the inventory code is pre-filled' do
        within('.field', text: _('Inventory Code')) do
          expect(find('input').value).not_to be_blank
          @inventory_code = find('input').value
        end
      end

      step 'I fill in the software' do
        selector = 'div#software_model_id input'
        type_into_and_select_from_autocomplete(selector, @software.name)
        @attributes = { model_id: @software.id }
      end

      step 'I fill in the version 3.61 for the license' do
        find('.field[data-id=license_version]').find('input').set('3.61')
        @attributes.merge!(item_version: '3.61')
      end

      step 'I fill in a serial number' do
        serial_number = Faker::Lorem.characters(number: 8)
        fill_in 'item[serial_number]', with: serial_number
        @attributes.merge!(serial_number: serial_number)
      end

      step 'I choose dongle as activation type' do
        select 'Dongle', from: 'item[properties][activation_type]'
        @attributes[:properties] ||= {}
        @attributes[:properties].merge!(activation_type: 'dongle')
      end

      step 'the field :field is visible' do |field|
        find('.field', text: field)
      end

      step 'the field :field is required' do |field|
        f = find('.field', text: field)
        expect(f['data-required']).to be == 'true'
      end

      step "I select 'Multiple Workplace' for license type" do
        select 'Multiple Workplace', from: 'item[properties][license_type]'
        @attributes[:properties].merge!(license_type: 'multiple_workplace')
      end

      step 'I fill in the value of total quantity' do
        total_quantity = '20'
        fill_in 'item[properties][total_quantity]', with: total_quantity
        @attributes[:properties].merge!(total_quantity: total_quantity)
      end

      step 'I add a quantity allocation' do
        quantity = '20'
        room = Faker::Lorem.word
        within('.field', text: _('Quantity allocations')) do
          find('.fa-plus').click
          find('input[data-quantity-allocation]').set quantity
          find('input[data-room-allocation]').set room
        end
        @attributes[:properties].merge!(
          quantity_allocations: [{ quantity: quantity, room: room }]
        )
      end

      step "I check 'Linux' for operating system" do
        f = find('.field', text: _('Operating System'))
        f.find('label', text: 'Linux').find('input').click
        @attributes[:properties].merge!(operating_system: ['linux'])
      end

      step "I check 'Local' and 'Web' for installation" do
        f = find('.field', text: _('Installation'))
        f.find('label', text: 'Local').find('input').click
        f.find('label', text: 'Web').find('input').click
        @attributes[:properties].merge!(installation: ['local', 'web'])
      end

      step 'I set a date for license expiration' do
        within('.field', text: _('License expiration')) do
          find('input').set '01/01/2099'
        end
        @attributes[:properties].merge!(license_expiration: '2099-01-01')
      end

      step "I select 'No' for maintenance contract" do
        select 'No', from: 'item[properties][maintenance_contract]'
        @attributes[:properties].merge!(maintenance_contract: 'false')
      end

      step 'the field :field is not visible' do |field|
        expect(page).not_to \
          have_selector('.field', text: /^#{field}/)
      end

      step "I select 'Yes' for maintenance contract" do
        select 'Yes', from: 'item[properties][maintenance_contract]'
        @attributes[:properties].merge!(maintenance_contract: 'true')
      end

      step 'I set a date for maintenance expiration' do
        within('.field', text: _('Maintenance expiration')) do
          find('input').set '01/01/2099'
        end
        @attributes[:properties].merge!(maintenance_expiration: '2099-01-01')
      end

      step "I select radio button 'Investition' for reference" do
        within('.field', text: _('Reference')) do
          find('label', text: 'Investment').find('input').click
        end
        @attributes[:properties].merge!(reference: 'investment')
      end

      step "I select 'OK' for borrowable" do
        within('.field', text: _('Borrowable')) do
          find('label', text: 'OK').find('input').click
        end
        @attributes.merge!(is_borrowable: true)
      end

      step 'I fill in the dongle ID' do
        dongle_id = Faker::Lorem.characters(number: 8)
        fill_in 'item[properties][dongle_id]', with: dongle_id
        @attributes[:properties].merge!(dongle_id: dongle_id)
      end

      step 'I fill in the project number' do
        project_number = Faker::Lorem.characters(number: 8)
        fill_in 'item[properties][project_number]', with: project_number
        @attributes[:properties].merge!(project_number: project_number)
      end

      step 'the license has been saved in the database successfully' do
        license = nil
        wait_until do
          license = Item.find_by_inventory_code(@inventory_code)
        end
        expect(license.attributes.deep_include? @attributes.deep_stringify_keys)
          .to be true
      end

      #############################################################################

      class ::Hash
        def deep_include?(sub_hash)
          sub_hash.keys.all? do |key|
            self.key?(key) && (
              if sub_hash[key].is_a?(Hash)
                self[key].is_a?(Hash) && self[key].deep_include?(sub_hash[key])
              else
                self[key] == sub_hash[key]
              end)
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::CreateSoftwareLicenseSteps,
                 manage_create_software_license: true
end
