require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative 'shared/personas_dump_steps'

placeholder :section_name do
  match /(manage section|borrow section)/ do |section|
    section
  end
end

module LeihsAdmin
  module Spec
    module MaintenanceModeSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps

      step 'I am in the system-wide settings' do
        visit admin.settings_path unless current_path == admin.settings_path
      end

      step 'I choose the function :function_name' do |function_name|
        @disable = true
        selector = @current_inventory_pool ? '.row.emboss' : '.form-group'
        case function_name
        when 'Disable manage section'
          input_field = \
            find(selector, text: :disable_manage_section, match: :first)
            .find("input[name='setting[#{:disable_manage_section}]']",
                  match: :first)
        when 'Disable borrow section'
          input_field = \
            find(selector, text: :disable_borrow_section, match: :first)
            .find("input[name='setting[#{:disable_borrow_section}]']",
                  match: :first)
        else
          raise
        end

        # these elements get displaced on Cider
        remove_nav
        remove_footer

        input_field.click
      end

      step 'I have to enter a note' do
        step 'I save'
        step 'I see an error message'
      end

      step 'the ":section_name" is disabled for users' do |section_name|
        step 'I log out'
        case section_name
        when 'manage section'
          step %(I am Mike)
          expect(current_path)
            .to eq manage_maintenance_path(@current_inventory_pool)
          @section = _('Manage section')
        when 'borrow section'
          step %(I am Normin)
          expect(current_path).to eq borrow_maintenance_path
          @section = _('Borrow section')
        else
          raise
        end
      end

      step 'users see the note that was defined' do
        expect(has_selector?('h1', text: _('%s not available') % @section))
          .to be true
        expect(has_content?(@disable_message)).to be true
      end

      step 'I enter a note for the ":section_name"' do |section_name|
        @disable_message = Faker::Lorem.sentence
        selector = @current_inventory_pool ? '.row.emboss' : '.form-group'
        case section_name
        when 'manage section'
          find(selector, text: :disable_manage_section_message, match: :first)
            .find("textarea[name='setting[#{:disable_manage_section_message}]']",
                  match: :first)
            .set @disable_message
        when 'borrow section'
          find(selector, text: :disable_borrow_section_message, match: :first)
            .find("textarea[name='setting[#{:disable_borrow_section_message}]']",
                  match: :first)
            .set @disable_message
        else
          raise
        end
      end

      step 'the settings for the ":section_name" were saved' do |section_name|
        case section_name
        when 'manage section'
          expect(Setting.disable_manage_section).to eq @disable
          expect(Setting.disable_manage_section_message.to_s)
            .to eq @disable_message
        when 'borrow section'
          expect(Setting.disable_borrow_section).to eq @disable
          expect(Setting.disable_borrow_section_message.to_s)
            .to eq @disable_message
        else
          raise
        end
      end

      step 'the ":section_name" is disabled' do |section_name|
        @setting = Setting.first
        @disable_message = Faker::Lorem.sentence

        case section_name
        when 'manage section'
          @setting.update_attributes \
            disable_manage_section: true,
            disable_manage_section_message: @disable_message
        when 'borrow section'
          @setting.update_attributes \
            disable_borrow_section: true,
            disable_borrow_section_message: @disable_message
        else
          raise
        end
      end

      step 'I deselect the :function_name option' do |function_name|
        @disable = false
        selector = @current_inventory_pool ? '.row.emboss' : '.form-group'
        case function_name
        when 'disable manage section'
          input_field = \
            find(selector, text: :disable_manage_section, match: :first)
            .find("input[name='setting[#{:disable_manage_section}]']",
                  match: :first)
        when 'disable borrow section'
          input_field = \
            find(selector, text: :disable_borrow_section, match: :first)
            .find("input[name='setting[#{:disable_borrow_section}]']",
                  match: :first)
        else
          raise
        end

        remove_nav
        remove_footer
        input_field.click
      end

      step 'the ":section_name" is not disabled for users' do |section_name|
        step 'I log out'
        case section_name
        when 'manage section'
          step %(I am Mike)
          expect(current_path).to eq manage_inventory_path(@current_inventory_pool)
        when 'borrow section'
          step %(I am Normin)
          expect(current_path).to eq borrow_root_path
        else
          raise
        end
      end

      step 'the note entered for the ":section_name" ' \
           'is still saved' do |section_name|
        case section_name
        when 'manage section'
          expect(@setting.reload.disable_manage_section_message)
            .to eq @disable_message
        when 'borrow section'
          expect(@setting.reload.disable_borrow_section_message)
            .to eq @disable_message
        else
          raise
        end
      end

      step 'I save' do
        scroll_to_top
        click_on _('Save')
      end
    end
  end
end

RSpec.configure do |config|
  config.include(LeihsAdmin::Spec::MaintenanceModeSteps,
                 leihs_admin_maintenance_mode: true)
end
