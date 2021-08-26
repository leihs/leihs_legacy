require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module EditOrderSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step "I enter the item's model name in the :add_assign input field" \
        do |add_assign|
        find('#add-input input').set @item.model.name
      end

      step "I enter the model's name in the :add_assign input field" \
        do |add_assign|
        find('#add-input input').set @model.name
      end

      step 'I open the order' do
        visit "/manage/#{@current_inventory_pool.id}/orders/#{@order.id}/edit"
      end

      step "the results of the autocomplete menu are empty" do
        within '.ui-autocomplete' do
          expect(current_scope).to have_content _("No results")
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::EditOrderSteps,
                 manage_edit_order: true
end
