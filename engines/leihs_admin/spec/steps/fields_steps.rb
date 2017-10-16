require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative '../../../../spec/steps/shared/factory_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module FieldsSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps
      include ::Spec::FactorySteps

      step 'I open the fields page' do
        visit admin.fields_path
      end

      step 'I see all fields' do
        Field.unscoped.all.map(&:id).each do |field_id|
          expect(page).to have_content field_id
        end
      end

      step 'the data of all fields is readonly' do
        within 'form' do
          expect(current_scope).not_to have_selector "input[type='text']"
        end
      end

      step 'the activate checkbox of a non-required field is enabled' do
        field = Field.unscoped.all.detect { |f| not f.data['required'] }
        expect(find("input[name='fields[#{field.id}][active]']"))
          .not_to be_disabled
      end

      step 'the activate checkbox of a required field is disabled' do
        field = Field.unscoped.all.detect { |f| f.data['required'] }
        expect(find("input[name='fields[#{field.id}][active]']"))
          .to be_disabled
      end

      step 'I store the information about the active state of all fields' do
        @fields = \
          Field.unscoped.all.map { |f| f.attributes.slice('id', 'active') }
      end

      step 'there is at least one inactive field' do
        unless Field.unscoped.find_by_active(false)
          field = Field.unscoped.all.detect { |f| not f.data['required'] }
          field.update_attributes!(active: false)
        end
        expect(Field.unscoped.find_by_active(false)).to be
      end

      step 'I deactivate an active field' do
        @active_field = Field.unscoped.find_by_active(false)
        expect(@active_field.active).to be false
        ###########################################################################
        # these elements sometimes cover stuff we want to click
        execute_script %($('header').remove())
        execute_script %($('footer').remove())
        sleep 1
        ###########################################################################
        uncheck("fields[#{@active_field.id}][active]")
      end

      step 'I activate an inactive field' do
        @inactive_field = Field.unscoped.find_by_active(true)
        expect(@inactive_field).to be
        ###########################################################################
        # these elements sometimes cover stuff we want to click
        execute_script %($('header').remove())
        execute_script %($('footer').remove())
        sleep 1
        ###########################################################################
        check("fields[#{@inactive_field.id}][active]")
      end

      step 'I update' do
        click_on _('Update')
      end

      step 'I see a success message that ' \
           'the fields have been updated successfully' do
        find('.alert-success', text: _('Fields have been updated successfully.'))
      end

      step 'the formerly active field is now inactive' do
        expect(find("input[name='fields[#{@active_field.id}][active]']"))
          .not_to be_checked
      end

      step 'the formerly inactive field is now active' do
        expect(find("input[name='fields[#{@inactive_field.id}][active]']"))
          .to be_checked
      end

      step 'all other fields remained unchanged' do
        @fields
          .reject { |f| [@inactive_field.id, @active_field.id].include? f['id'] }
          .each do |field|
          expect(find("input[name='fields[#{field['id']}][active]']").checked?)
            .to be field['active']
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include(LeihsAdmin::Spec::FieldsSteps,
                 leihs_admin_fields: true)
end
