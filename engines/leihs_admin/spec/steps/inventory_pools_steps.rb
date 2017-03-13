require_relative 'shared/common_steps'
require_relative 'shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

placeholder :input_label do
  match(/(.*)/) do |value|
    value
  end
end

# rubocop:disable Metrics/ModuleLength
module LeihsAdmin
  module Spec
    module InventoryPoolsSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::LoginSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps

      step 'I navigate to the admin area' do
        within 'nav.topbar' do
          find('.navbar-right .dropdown-toggle', match: :first).click
          find('.navbar-right .dropdown-menu a', text: _('Admin')).click
        end
      end

      step 'I create a new inventory pool in the ' \
           'admin area\'s inventory pool tab' do
        expect(current_path).to eq admin.inventory_pools_path
        click_link _('Create %s') % _('Inventory pool')
      end

      step 'I enter name, shortname and email address' do
        find("input[name='inventory_pool[name]']").set 'test'
        find("input[name='inventory_pool[shortname]']").set 'test'
        find("input[name='inventory_pool[email]']").set 'test@test.ch'
      end

      step 'the inventory pool is saved' do
        expect(
          InventoryPool
          .find_by_name_and_shortname_and_email('test', 'test', 'test@test.ch')
        ).not_to be_nil
      end

      step 'I see the list of all inventory pools' do
        expect(has_content?(_('List of Inventory Pools'))).to be true
        within '.list-of-lines' do
          InventoryPool.all.each do |ip|
            find '.row', match: :prefer_exact, text: ip.name
          end
        end
      end

      step 'I don\'t enter :must_field' do |must_field|
        step 'I enter name, shortname and email address'
        within('.form-group .col-sm-6 strong', match: :first, text: must_field) do
          find(:xpath, './../..').find('input').set ''
        end
      end

      step 'the inventory pool is not created' do
        expect(has_no_content?(_('List of Inventory Pools'))).to be true
        expect(has_no_selector?('.success')).to be true
      end

      step 'I edit in the admin area\'s inventory pool tab ' \
           'an existing inventory pool' do
        @current_inventory_pool = InventoryPool.first
        expect(has_content?(_('List of Inventory Pools'))).to be true
        find('.row', match: :prefer_exact, text: @current_inventory_pool.name)
          .click_link _('Edit')
      end

      step 'I change name, shortname and email address' do
        all('.row .col-sm-6 strong', text: _('Name'))
          .first.find(:xpath, './../..').find('input').set 'test'
        all('.row .col-sm-6 strong', text: _('Short Name'))
          .first.find(:xpath, './../..').find('input').set 'test'
        all('.row .col-sm-6 strong', text: _('E-Mail'))
          .first.find(:xpath, './../..').find('input').set 'test@test.ch'
      end

      step 'I delete an existing inventory pool ' \
           'in the admin area\'s inventory pool tab' do
        @current_inventory_pool = \
          InventoryPool.find(&:can_destroy?) || FactoryGirl.create(:inventory_pool)
        visit admin.inventory_pools_path
        within('.row', text: @current_inventory_pool.name) do
          find(:xpath, '.').click # NOTE it scrolls to the target line
          within '.line-actions' do
            find('.dropdown-toggle').click
            find('.dropdown-menu a', text: _('Delete')).click
          end
        end
      end

      step 'the inventory pool is removed from the list' do
        find('#flash .success',
             text: _('%s successfully deleted') % _('Inventory Pool'))
        expect(has_no_content?(@current_inventory_pool.name)).to be true
      end

      step 'the inventory pool is deleted from the database' do
        expect(InventoryPool.find_by_name(@current_inventory_pool.name)).to eq nil
      end

      step 'the list of inventory pools is sorted alphabetically' do
        names = \
          all('div.dropdown-holder:nth-child(1) .dropdown .dropdown-item')
          .map(&:text)
        expect(names.map(&:downcase).sort).to eq names.map(&:downcase)
      end

      step 'I see all managed inventory pools' do
        if @current_user.inventory_pools.managed.exists?
          within '#ip-dropdown-menu' do
            @current_user.inventory_pools.managed.each \
              { |ip| has_content? ip.name }
          end
        end
      end

      step 'I click the navigation toggler' do
        find('nav.navbar .navbar-right > .dropdown', match: :first).click
      end

      step 'I don\'t fill in :input_label' do |input_label|
        expect(
          find('.form-group', text: input_label, match: :prefer_exact)
          .find('input')
          .value
        ).to be_blank
      end

      step 'multiple inventory pools are granting automatic access' do
        InventoryPool.limit(rand(2..4)).each do |inventory_pool|
          inventory_pool.update_attributes automatic_access: true
        end
        inventory_pool = \
          @current_user
          .inventory_pools
          .managed
          .where.not(automatic_access: true)
          .first
        if inventory_pool
          inventory_pool.update_attributes automatic_access: true
        end
        @inventory_pools_with_automatic_access = \
          InventoryPool.where(automatic_access: true)
        expect(@inventory_pools_with_automatic_access.count).to be > 1
      end

      step 'I have created a user with ' \
           'login :login and password :password' do |login, password|
        visit admin.new_user_path
        fill_in_user_information(firstname: 'test',
                                 lastname: 'test',
                                 email: 'test@test.ch',
                                 login: login,
                                 password: password,
                                 password_confirmation: password)
        expect(has_content?(_('List of Users'))).to be true
        @user = User.find_by_login(login)
        expect(DatabaseAuthentication.find_by_user_id(@user.id)).not_to be_nil
      end

      step 'the newly created user has \'customer\'-level access to all ' \
           'inventory pools that grant automatic access' do
        expect(@user.access_rights.count)
          .to eq @inventory_pools_with_automatic_access.count
        expect(@user.access_rights.pluck(:inventory_pool_id))
          .to eq @inventory_pools_with_automatic_access.pluck(:id)
        expect(@user.access_rights.all? { |ar| ar.role == :customer }).to be true
      end

      private

      def fill_in_user_information(attrs)
        selector = @current_inventory_pool ? '.row.emboss' : '.form-group'
        find(selector, match: :prefer_exact, text: _('Last name'))
          .find('input').set attrs[:firstname] if attrs[:lastname]
        find(selector, match: :prefer_exact, text: _('First name'))
          .find('input').set attrs[:firstname] if attrs[:firstname]
        find(selector, match: :prefer_exact, text: _('E-Mail'))
          .find('input').set attrs[:email] if attrs[:email]
        find(selector, match: :prefer_exact, text: _('Login'))
          .find('input').set attrs[:login] if attrs[:login]
        find(selector, match: :prefer_exact, text: _('Password'))
          .find('input').set attrs[:password] if attrs[:password]
        if attrs[:password_confirmation]
          find(selector, match: :prefer_exact, text: _('Password Confirmation'))
            .find('input').set attrs[:password_confirmation]
        end
        click_button _('Save')
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength

RSpec.configure do |config|
  config.include(LeihsAdmin::Spec::InventoryPoolsSteps,
                 leihs_admin_inventory_pools: true)
end
