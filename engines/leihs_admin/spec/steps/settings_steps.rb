require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module SettingsSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps

      step 'I edit the following settings' do |table|
        @new_settings = {}
        within("form#edit_setting[action='/admin/settings']") do
          table.raw.flatten.each do |k|
            begin
              case k
              when \
                'email_signature',
                'external_base_url',
                'ldap_config',
                'mail_delivery_method',
                'smtp_address',
                'smtp_domain',
                'smtp_openssl_verify_mode',
                'smtp_password',
                'smtp_username',
                'user_image_url'
                field = find("input[name='setting[#{k}]']")
                expect(Setting.send(k).to_s).to eq field.value
                @new_settings[k] = new_value = Faker::Lorem.word
                field.set new_value
              when 'logo_url'
                field = find("input[name='setting[#{k}]']")
                expect(Setting.send(k).to_s).to eq field.value
                @new_settings[k] = field.value
              when 'default_email'
                field = find("input[name='setting[#{k}]']")
                expect(Setting.send(k).to_s).to eq field.value
                @new_settings[k] = new_value = Faker::Internet.email
                field.set new_value
              when \
                'contract_lending_party_string',
                'contract_terms',
                'custom_head_tag'
                field = find("textarea[name='setting[#{k}]']")
                expect(Setting.send(k).to_s).to eq field.value
                @new_settings[k] = new_value = Faker::Lorem.paragraph
                field.set new_value
              when 'deliver_order_notifications', 'smtp_enable_starttls_auto'
                field = find("input[name='setting[#{k}]']")
                expect(Setting.send(k)).to eq field.checked?
                # TODO: @new_settings[k]
                field.click
              when 'smtp_port'
                field = find("input[name='setting[#{k}]']")
                expect(Setting.send(k).to_s).to eq field.value
                @new_settings[k] = new_value = rand(0..10000)
                field.set new_value
              when 'time_zone', 'local_currency_string'
                field = find("select[name='setting[#{k}]']")
                expect(Setting.send(k).to_s).to eq field.value
                @new_settings[k] = new_value = field.all('option').sample[:value]
                field.select new_value
              else
                raise format('%s not found', k)
              end
            rescue Selenium::WebDriver::Error::UnknownError
              page.execute_script %[ $(".navbar").remove() ]
              retry
            end
          end
        end
        scroll_to_top
        find("button.btn.btn-success[type='submit']").click
      end

      step 'the settings are persisted' do
        find('#flash .notice', text: _('Successfully set.'))
        @new_settings.each_pair do |k, v|
          expect(Setting.send(k).presence).to eq v.presence
        end
      end

      step 'I go to the settings page' do
        visit admin.settings_path
      end

      step 'I am on the settings page' do
        expect(current_path).to be == admin.settings_path
      end
    end
  end
end

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::SettingsSteps, leihs_admin_settings: true
end
