require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module EditUserSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'there is a group in the current pool' do
        @group = FactoryBot.create(:group,
                                    inventory_pool: @current_inventory_pool)
      end

      step 'the user belongs to this group' do
        @user.entitlement_groups << @group
      end

      step 'open the edit page of the user' do
        visit manage_edit_inventory_pool_user_path(@current_inventory_pool,
                                                   @user)
      end

      step 'I remove the group' do
        within '#change-groups .list-of-lines' do
          click_button _('Remove')
        end
      end

      step 'I save' do
        click_button _('Save')
      end

      step 'the user does not belong to any group' do
        within '#change-groups .list-of-lines' do
          expect(current_scope).not_to have_selector '.line'
        end
        expect(@user.reload.entitlement_groups).to be_empty
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::EditUserSteps,
                 manage_edit_user: true
end
