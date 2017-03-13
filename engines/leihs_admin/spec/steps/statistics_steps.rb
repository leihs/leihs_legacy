require_relative 'shared/login_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module StatisticsSteps
      include ::LeihsAdmin::Spec::LoginSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps

      step 'I am in the admin section' do
        visit admin.root_path
      end

      step 'I can choose to switch to the statistics section' do
        find("a[href='#{admin.statistics_path}']", match: :first)
      end

      step 'I am in the statistics section' do
        visit('/admin/statistics')
      end

      step "the page title is 'Statistics'" do
        find('h2', text: _('Statistics'))
      end

      step 'I select the statistics subsection ' \
           ':subsection_title' do |subsection_title|
        click_link(subsection_title)
      end

      step 'I see by default the last ' \
           ':number_of_days days\' statistics' do |number_of_days|
        from_date = Date.parse(all('input.datepicker').first.value)
        to_date = Date.parse(all('input.datepicker')[1].value)
        expect((to_date - from_date).days).to eq(Integer(number_of_days).days)
      end

      step 'I set the time frame to ' \
           ':from_day/:from_month - :to_day/:to_month ' \
           'of the current year' do |from_day, from_month, to_day, to_month|
        start_date = \
          Date.parse("#{from_day}/#{from_month}/#{Date.today.strftime('%Y')}")
        end_date = \
          Date.parse("#{to_day}/#{to_month}/#{Date.today.strftime('%Y')}")
        all('input.datepicker').first.set start_date
        all('input.datepicker')[1].set end_date
      end
    end
  end
end

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::StatisticsSteps, leihs_admin_statistics: true
end
