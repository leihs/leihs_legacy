require_relative 'shared/common_steps'
require_relative 'shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module InventoryCsvSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::LoginSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps

      step "I click on the dropdown toggle for 'Export Inventory'" do
        find('.dropdown-toggle', text: "#{_('Export')} #{_('Inventory')}").click
      end
    end
  end
end

RSpec.configure do |config|
  config.include(LeihsAdmin::Spec::InventoryCsvSteps,
                 leihs_admin_inventory_csv: true)
end
