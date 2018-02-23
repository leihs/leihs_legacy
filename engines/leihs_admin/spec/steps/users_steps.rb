require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module UsersSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps

      step 'I am editing a user that has no access rights and is not an admin' do
        @user = User.find { |u| not u.is_admin and u.has_role? :customer }
        @previous_access_rights = @user.access_rights.freeze
        visit admin.edit_user_path(@user)
      end

      step 'I assign the admin role to this user' do
        select _('Yes'), from: 'user_admin'
      end

      step 'this user has the admin role' do
        expect(@user.reload.is_admin).to be true
      end

      step 'all their previous access rights remain intact' do
        expect((@previous_access_rights - @user.access_rights.reload).empty?)
          .to be true
      end

      step 'I am editing a user who has the admin role ' \
           'and access to inventory pools' do
        @user = User.find { |u| u.is_admin and u.has_role? :customer }
        raise 'user not found' unless @user
        @previous_access_rights = @user.access_rights.freeze
        visit admin.edit_user_path(@user)
      end

      step 'I remove the admin role from this user' do
        select _('No'), from: 'user_admin'
      end

      step 'this user no longer has the admin role' do
        expect(@user.reload.is_admin).to be false
      end

      step 'I navigate from here to the user creation page' do
        click_link _('New User')
      end

      step 'I enter the following information' do |table|
        selector = '.form-group'
        table.raw.flatten.each do |field_name|
          find(selector, match: :prefer_exact, text: field_name)
            .find('input,textarea')
            .set (field_name == 'E-Mail' ? 'test@test.ch' : 'test')
        end
      end

      step 'I enter the login data' do
        selector = '.form-group'
        find(selector, match: :prefer_exact, text: _('Login'))
          .find('input').set 'username'
        find(selector, match: :prefer_exact, text: _('Password'))
          .find('input').set 'password'
        find(selector, match: :prefer_exact, text: _('Password Confirmation'))
          .find('input').set 'password'
      end

      step 'I am redirected to the user list outside an inventory pool' do
        expect(current_path).to eq admin.users_path
      end

      step 'the new user has been created' do
        @user = User.find_by_email 'test@test.ch'
      end

      step 'he does not have access to any inventory pools ' \
           'and is not an administrator' do
        expect(@user.access_rights.active.empty?).to be true
      end

      step 'I pick a user without access rights, orders or contracts' do
        @user = User.find do |u|
          u.access_rights.active.empty? and u.orders.empty? and u.contracts.empty?
        end
      end

      step 'I delete that user from the list' do
        step 'I search for the user'
        within('#user-list .row', text: @user.name) do
          within('.line-actions') do
            find('.dropdown-toggle').click
            find('.dropdown-menu .bg-danger a', text: _('Delete')).click
          end
        end
        step 'I confirm the dialog'
      end

      step 'I search for the user' do
        within '#list-filters' do
          fill_in 'search_term', with: @user.name
        end
        click_on _('Search')
      end

      step 'that user has been deleted from the list' do
        expect(has_no_selector?('#user-list .line', text: @user.name)).to be true
      end

      step 'that user does not exist anymore' do
        expect(User.find_by_id(@user.id)).to eq nil
      end

      step 'I do not have access as manager to any inventory pools' do
        expect(
          @current_user
          .access_rights
          .where(role: [:group_manager, :lending_manager, :inventory_manager])
          .exists?
        ).to be false
      end

      step 'I am redirected to the login page' do
        find('h1', text: _('Login'))
        find("form[action='/authenticator/login']")
      end

      step 'I open the list of users in an inventory pool' do
        @current_inventory_pool = \
          @current_user.inventory_pools.managed.sample || InventoryPool.first
        visit manage_inventory_pool_users_path(@current_inventory_pool)
      end

      step 'I edit a user that has access rights' do
        @user = User.find { |u| u.access_rights.active.count >= 2 }
        expect(@user.access_rights.active.count).to be >= 2
        visit admin.edit_user_path(@user)
      end

      step 'inventory pools they have access to ' \
           'are listed with the respective role' do
        @user.access_rights.active.each do |access_right|
          find('.well ul > li', text: access_right.to_s)
        end
      end

      step 'I pick one user with access rights, ' \
           'one with orders and one with contracts' do
        @users = []
        @users << User.find { |u| not u.access_rights.active.empty? }
        @users << User.find { |u| not u.orders.empty? }
        @users << User.find { |u| not u.contracts.empty? }
      end

      step 'the delete button for every picked user is not present' do
        @users.each do |user|
          @user = user
          step 'I search for the user'
          within('#user-list .row', text: @user.name) do
            within('.line-actions') do
              find('.dropdown-toggle').click
              expect(has_no_selector?('.dropdown-menu a', text: _('Delete')))
                .to be true
            end
          end
        end
      end

      step 'the currently active tab is :tab_label' do |tab_label|
        view = find('#user-index-view')
        expect(view.find('.nav-tabs li.active').text).to eq tab_label
      end

      step 'I change the tab to :tab_label' do |tab_label|
        view = find('#user-index-view')
        view.find('.nav-tabs li', text: tab_label).click
      end

      step 'I pick any user' do
        @user = User.all.sample
      end

      step 'I pick an admin user' do
        @user = User.admins.sample
      end

      step 'I search the Users list for the picked users name' do
        within '#user-index-view #list-filters' do
          find('[name=search_term]').set("#{@user.firstname} #{@user.lastname}")
          find('[type=submit]').click
        end
      end

      step 'I see the picked user in the results' do
        within '#user-index-view #user-list' do
          expect(find('.row', text: "#{@user.firstname} #{@user.lastname}")).to be
        end
      end

    end
  end
end

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::UsersSteps, leihs_admin_users: true
end
