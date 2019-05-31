require_relative '../shared/common_steps'
require_relative '../shared/factory_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module DelegationsSteps
      include ::Spec::CommonSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'the user is a member of the delegation' do
        @delegation.delegated_users << @user
        @delegation.save!
      end

      step 'the user has a session for the delegation' do
        auth_system = AuthenticationSystem.find_by(type: 'password') ||
          AuthenticationSystem.create(id: 'password',
                                      name: 'leihs password',
                                      type: 'password')

        FactoryGirl.create(:user_session,
                           user: @user,
                           authentication_system: auth_system,
                           delegation: @delegation)
      end

      step 'the user has unsubmitted reservation for the delegation' do
        FactoryGirl.create(:reservation,
                           status: :unsubmitted,
                           user: @delegation,
                           delegated_user: @user,
                           inventory_pool: @current_inventory_pool)
      end

      step 'the user has submitted reservation for the delegation' do
        ActiveRecord::Base.transaction do
          order = FactoryGirl.create(:order,
                                     user: @delegation,
                                     state: :submitted,
                                     inventory_pool: @current_inventory_pool)
          @submitted_reservation = \
            FactoryGirl.create(:reservation,
                               :with_assigned_item,
                               status: :submitted,
                               user: @delegation,
                               order: order,
                               delegated_user: @user,
                               inventory_pool: @current_inventory_pool)
        end
      end

      step 'the user has rejected reservation for the delegation' do
        ActiveRecord::Base.transaction do
          order = FactoryGirl.create(:order,
                                     user: @delegation,
                                     state: :rejected,
                                     inventory_pool: @current_inventory_pool)
          @rejected_reservation = \
            FactoryGirl.create(:reservation,
                               :with_assigned_item,
                               status: :rejected,
                               user: @delegation,
                               order: order,
                               delegated_user: @user,
                               inventory_pool: @current_inventory_pool)
        end
      end

      step 'the user has closed reservation for the delegation' do
        ActiveRecord::Base.transaction do
          contract = FactoryGirl.create(:closed_contract,
                                        user: @delegation,
                                        contact_person: @user,
                                        inventory_pool: @current_inventory_pool)
          @closed_reservation = \
            FactoryGirl.create(:reservation,
                               :with_assigned_item,
                               status: :closed,
                               user: @delegation,
                               delegated_user: @user,
                               contract: contract,
                               inventory_pool: @current_inventory_pool)
        end
      end

      step 'the user has a submitted reservation' do
        ActiveRecord::Base.transaction do
          order = FactoryGirl.create(:order,
                                     user: @user,
                                     state: :submitted,
                                     inventory_pool: @current_inventory_pool)
          @submitted_reservation = \
            FactoryGirl.create(:reservation,
                               status: :submitted,
                               user: @user,
                               order: order,
                               inventory_pool: @current_inventory_pool)
        end
      end

      step 'I open the edit page of the delegation' do
        visit manage_edit_inventory_pool_user_path(@current_inventory_pool,
                                                   @delegation)
      end

      step 'I remove the user' do
        find('#users .line', text: @user.name)
          .find('button', _('Remove'))
          .click
      end

      step 'I save' do
        click_on _('Save')
      end

      step 'the user is no longer member of the delegation' do
        expect(@delegation.reload.delegated_users.map(&:id))
          .not_to include @user.id
      end

      step 'the user does not have any unsubmitted reservations ' \
           'for the delegation' do
        expect(
          Reservation.where(user: @delegation,
                            delegated_user: @user,
                            status: :unsubmitted)
        ).to be_empty
      end

      step 'the user has still the same submitted reservation ' \
           'for the delegation' do
        expect(@submitted_reservation.reload).to be
      end

      step 'the user has still the same submitted reservation ' \
           'for the delegation' do
        expect(@submitted_reservation.reload).to be
      end

      step 'the user has still the same rejected reservation for the delegation' do
        expect(@rejected_reservation.reload).to be
      end

      step 'the user has still the same closed reservation for the delegation' do
        expect(@closed_reservation.reload).to be
      end

      step 'the user has still the same submitted reservation' do
        expect(@submitted_reservation.reload).to be
      end

      step 'the user does not have any session for the delegation anymore' do
        expect(UserSession.where(user: @user, delegation: @delegation)).to be_empty
      end

      step 'the user is still member of the delegation' do
        expect(@delegation.reload.delegated_users.map(&:id))
          .to include @user.id
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::DelegationsSteps,
                 manage_delegations: true
end
