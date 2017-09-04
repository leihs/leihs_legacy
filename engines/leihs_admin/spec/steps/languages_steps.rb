require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module LanguagesSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps

      step 'I see a table of configured languages as follows' do |table|
        displayed_table = find('.container table.table')
          .all('tr').map { |tr| tr.all('th, td').map(&:text) }

        expect(displayed_table).to eq table.raw
      end

    end
  end
end
# rubocop:enable Metrics/ModuleLength

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::LanguagesSteps, leihs_admin_languages: true
end
