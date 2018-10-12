require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module InventorySteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'there is an item the current pool is owner of ' \
           'situated in room :room' do |room|
        FactoryGirl.create(:item,
                           owner: @current_inventory_pool,
                           room: FactoryGirl.create(:room,
                                                    name: room))
      end

      step 'I open the inventory list page' do
        visit manage_inventory_path(@current_inventory_pool)
      end

      step 'I search after :search_string' do |search_string|
        fill_in 'list-search', with: search_string
      end

      step 'I see one model line corresponding to the item ' \
           'situated in :room' do |room|
        items = Item.joins(:room).where(rooms: { name: room })
        expect(items.count).to be == 1
        item = Item.joins(:room).where(rooms: { name: room }).first
        within '#inventory' do
          find("[data-type='model']")
          expect(all("[data-type='model']").count).to be == 1
          expect(all("[data-type='model']").first.text).to match item.model.name
        end
      end

      step 'there are :n items for the model in the current inventory pool' do |n|
        n.to_i.times do
          FactoryGirl.create(:item,
                             model: @model,
                             owner: @current_inventory_pool,
                             inventory_pool: @current_inventory_pool)
        end
      end

      step 'there are :n licenses for the software ' \
           'in the current inventory pool' do |n|
        n.to_i.times do
          FactoryGirl.create(:license,
                             model: @software,
                             owner: @current_inventory_pool,
                             inventory_pool: @current_inventory_pool)
        end
      end

      step "I search after the model's name" do
        fill_in 'list-search', with: @model.name
      end

      step "I search after the software's name" do
        fill_in 'list-search', with: @software.name
      end

      step "I see one line corresponding to the model's name" do
        within '#inventory' do
          find("[data-type='model']")
          expect(all("[data-type='model']").count).to be == 1
          expect(all("[data-type='model']").first.text).to match @model.name
        end
      end

      step "I see one line corresponding to the software's name" do
        within '#inventory' do
          find("[data-type='software']")
          expect(all("[data-type='software']").count).to be == 1
          expect(all("[data-type='software']").first.text).to match @software.name
        end
      end

      step 'I open the dropdown for the :model_type' do |model_type|
        find('#inventory .line.row',
             text: instance_variable_get("@#{model_type}").name)
          .find("[data-type='inventory-expander']")
          .click
      end

      step 'the dropdown contains :n :item_type lines' do |n, _|
        @lines = all('.group-of-lines .line.row')
        expect(@lines.count).to eq n.to_i
      end

      step 'the :item_type lines are sorted alphabetically ' \
           'by their inventory code' do |item_type|
        model_type = case item_type
                     when 'item'
                       'model'
                     when 'license'
                       'software'
                     end
        expect(
          @lines.map { |l| l.first('.col2of5 .row').text }
        ).to eq(
          instance_variable_get("@#{model_type}")
          .items
          .send(item_type.pluralize)
          .order(:inventory_code).map(&:inventory_code)
        )
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::InventorySteps, manage_inventory: true
end
