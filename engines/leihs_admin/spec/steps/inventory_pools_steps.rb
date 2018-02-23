require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative '../../../../spec/steps/shared/factory_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

placeholder :input_label do
  match(/(.*)/) do |value|
    value
  end
end

module LeihsAdmin
  module Spec
    module InventoryPoolsSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps
      include ::Spec::FactorySteps

      step 'I navigate to the admin area' do
        visit '/admin'
        within 'nav.topbar' do
          find('.navbar-right .dropdown-toggle', match: :first).click
          find('.navbar-right .dropdown-menu a', text: _('Admin')).click
        end
      end

      step 'I navigate to the inventory pools page' do
        within 'nav.topbar' do
          find('.navbar-right .dropdown-toggle', match: :first).click
          find('.navbar-right .dropdown-menu a', text: _('Admin')).click
        end
        click_on 'Inventory Pools'
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
        @inventory_pool = \
          InventoryPool
          .find_by_name_and_shortname_and_email('test', 'test', 'test@test.ch')
        expect(@inventory_pool).to be
      end

      step 'I see the list of all active inventory pools sorted alphabetically' do
        expect(has_content?(_('List of Inventory Pools'))).to be true
        within '.list-of-lines' do
          expect(InventoryPool.where(is_active: true).sort.map(&:name))
            .to be == all('.row > .col-sm-6').map(&:text)
        end
      end

      step 'I see the list of all inventory pools' do
        expect(has_content?(_('List of Inventory Pools'))).to be true
        find '.list-of-lines'
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

      step "each line displays the inventory pool's name" do
        within '.list-of-lines' do
          InventoryPool.all.each do |ip|
            find '.row', match: :prefer_exact, text: ip.name
          end
        end
      end

      step "each line displays the inventory pool's short name" do
        within '.list-of-lines' do
          InventoryPool.all.each do |ip|
            find '.row', match: :prefer_exact, text: ip.shortname
          end
        end
      end

      step "each line displays the inventory pool's active state" do
        within '.list-of-lines' do
          InventoryPool.all.each do |ip|
            text = ip.is_active? ? _('active') : _('inactive')
            find '.row', match: :prefer_exact, text: text
          end
        end
      end

      step 'there exists an inventory pool' do
        @inventory_pool = FactoryGirl.create(:inventory_pool)
      end

      step 'the inventory pool has ' \
           "but doesn't own an unretired item" do
        FactoryGirl.create(:item,
                           inventory_pool: @inventory_pool,
                           owner: FactoryGirl.create(:inventory_pool))
      end

      step 'the inventory pool owns ' \
           "but doesn't have an unretired item" do
        FactoryGirl.create(:item,
                           inventory_pool: FactoryGirl.create(:inventory_pool),
                           owner: @inventory_pool)
      end

      step 'there exists an active inventory pool' do
        @active_inventory_pool = FactoryGirl.create(:inventory_pool,
                                                    is_active: true)
      end

      step 'there exists an inactive inventory pool' do
        @inactive_inventory_pool = FactoryGirl.create(:inventory_pool,
                                                      is_active: false)
      end

      step 'there exists an inventory pool with :order_type' do |order_type|
        @inventory_pool = FactoryGirl.create(:inventory_pool)
        case order_type
        when 'unsubmitted order'
          FactoryGirl.create(:reservation,
                             status: :unsubmitted,
                             inventory_pool: @inventory_pool)
        when 'submitted order'
          user = FactoryGirl.create(:customer, inventory_pool: @inventory_pool)
          order = FactoryGirl.create(:order,
                                     user: user,
                                     inventory_pool: @inventory_pool,
                                     state: :submitted)
          FactoryGirl.create(:reservation,
                             status: :submitted,
                             order: order,
                             inventory_pool: @inventory_pool)
        when 'approved order'
          user = FactoryGirl.create(:customer, inventory_pool: @inventory_pool)
          order = FactoryGirl.create(:order,
                                     user: user,
                                     inventory_pool: @inventory_pool,
                                     state: :approved)
          FactoryGirl.create(:reservation,
                             status: :approved,
                             order: order,
                             inventory_pool: @inventory_pool)
        when 'signed contract'
          FactoryGirl.create(:open_contract,
                             inventory_pool: @inventory_pool)
        end
      end

      step 'I open the edit page for an inventory pool' do
        visit admin.edit_inventory_pool_path(@inventory_pool)
      end

      step 'I select :yes_no from "Active?"' do |yes_no|
        select _(yes_no), from: 'inventory_pool_is_active'
      end

      step 'I see an error message regarding the deactivation of inventory pool' do
        expect(find('#flash .error').text)
          .to match /Inventory pool can't be deactivated/
      end

      step 'the inventory pool remains active' do
        expect(@inventory_pool.reload.is_active?).to be true
      end

      step 'I see a success message' do
        find('#flash .notice')
      end

      step 'the inventory pool became inactive' do
        expect(@inventory_pool.reload.is_active?).to be false
      end

      step 'there exists an inactive inventory pool ' \
           'I have access to as :role' do |role|
        @inactive_inventory_pool = \
          FactoryGirl.create(:inventory_pool, is_active: false)
        FactoryGirl.create(:access_right,
                           user: @current_user,
                           inventory_pool: @inactive_inventory_pool,
                           role: role.sub(' ', '_'))
      end

      step 'I click on the sections dropdown toggle' do
        el = find('#topbar .dropdown-toggle', match: :first)
        el.hover
      end

      step "I don't see the inactive inventory pool in the list" do
        within find('#topbar .dropdown', match: :first) do
          expect(page).not_to have_content @inactive_inventory_pool.name
        end
      end

      step 'there is no unsubmitted order for the deactivated inventory pool' do
        expect(@inventory_pool.reservations.unsubmitted.count).to be == 0
      end

      step 'the inventory pool does not have any unretired items' do
        @inventory_pool.items.each do |item|
          item.update_attributes(retired: Date.today,
                                 retired_reason: Faker::Lorem.sentence)
        end
      end

      step 'the activity filtering is set to :activity' do |activity|
        expect(find('select[name=activity]').value).to be == activity
      end

      step 'I can see the active inventory pool' do
        expect(page).to have_content @active_inventory_pool.name
      end

      step 'I can see the inactive inventory pool' do
        expect(page).to have_content @inactive_inventory_pool.name
      end

      step 'I can not see the active inventory pool' do
        expect(page).not_to have_content @active_inventory_pool.name
      end

      step 'I can not see the inactive inventory pool' do
        expect(page).not_to have_content @inactive_inventory_pool.name
      end

      step 'I filter for :activity activity' do |activity|
        find('select[name=activity]').select activity
        click_on 'Search'
      end

      step 'the user had access to the pool as inventory manager' do
        FactoryGirl.create(:access_right,
                           inventory_pool: @active_inventory_pool,
                           deleted_at: Date.yesterday,
                           role: :inventory_manager)
      end

      step 'I open the edit page for the active inventory pool' do
        visit admin.edit_inventory_pool_path(@active_inventory_pool)
      end

      step 'I add the user as inventory manager of the pool' do
        find("input[type='search']").set @user.name
        find('.select2-container li', text: @user.name).click
      end

      step 'the user has inventory manager access to the pool' do
        ar = @user.access_right_for(@active_inventory_pool)
        expect(ar).to be
        expect(ar.role).to be == :inventory_manager
      end

      step 'the mail templates have been created for the inventory pool' do
        template_types = {
          reminder: :user,
          deadline_soon_reminder: :user,
          received: :order,
          submitted: :order,
          approved: :order,
          rejected: :order
        }
        template_types.each do |name, type|
          mt = MailTemplate.find_by!(name: name,
                                     type: type,
                                     is_template_template: true)
          Language.all.each do |language|
            expect(
              MailTemplate.find_by(inventory_pool_id: @inventory_pool.id,
                                   is_template_template: false,
                                   language_id: language.id,
                                   name: name,
                                   type: type,
                                   format: 'text',
                                   body: mt.body)
            ).to be
          end
        end
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

RSpec.configure do |config|
  config.include(LeihsAdmin::Spec::InventoryPoolsSteps,
                 leihs_admin_inventory_pools: true)
end
