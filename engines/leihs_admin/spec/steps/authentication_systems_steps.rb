require_relative 'shared/common_steps'
require_relative 'shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module AuthenticationSystemsSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::LoginSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps

      step 'I see a list of authentication systems' do
        find('.nav-tabs .active', text: _('Authentication Systems'))
        within 'table' do
          AuthenticationSystem.all.each do |auth_system|
            find('tr > td', text: auth_system.name)
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::AuthenticationSystemsSteps,
                 leihs_admin_authentication_systems: true
end
