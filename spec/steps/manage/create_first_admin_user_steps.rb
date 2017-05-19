# require_relative 'shared/common_steps'
# require_relative '../shared/common_steps'
# require_relative '../shared/login_steps'
# require_relative '../shared/personas_dump_steps'

module Manage
  module Spec
    module CreateFirstAdminUserSteps
      # include ::Borrow::Spec::CommonSteps
      # include ::Spec::CommonSteps
      # include ::Spec::LoginSteps
      # include ::Spec::PersonasDumpSteps

      step 'a user exists' do
        FactoryGirl.create(:user)
      end

      step 'a user does not exist' do
        expect(User.exists?).to be false
      end

      step 'a database authentication system exists' do
        @auth_system = FactoryGirl.create(:authentication_system,
                                          class_name: 'DatabaseAuthentication')
      end

      step 'a database authentication system does not exist' do
        expect(
          AuthenticationSystem.where(class_name: 'DatabaseAuthentication').exists?
        ).to be false
      end

      step 'this authentication system is active and default' do
        @auth_system.update_attributes(is_active: true, is_default: true)
      end

      step 'I visit the root path' do
        visit root_path
      end

      step 'the root page with the login button is displayed' do
        find('a.button', text: _('Login'))
      end

      step 'the create first admin user page is displayed' do
        expect(current_path).to be == new_first_admin_user_path
      end

      step 'I fill in the firstname' do
        fill_in 'user[firstname]', with: Faker::Name.first_name
      end

      step 'I fill in the lastname' do
        @lastname = Faker::Name.last_name
        fill_in 'user[lastname]', with: @lastname
      end

      step 'I fill in the email' do
        fill_in 'user[email]', with: Faker::Internet.email
      end

      step 'I fill in the login' do
        @login = Faker::Internet.user_name
        fill_in 'db_auth[login]', with: @login
      end

      step 'I fill in the password' do
        @password = Faker::Internet.password
        fill_in 'db_auth[password]', with: @password
      end

      step 'I fill in the password confirmation' do
        fill_in 'db_auth[password_confirmation]', with: @password
      end

      step 'I click on save' do
        click_button _('Save')
      end

      step 'there is notice about successful creation of the admin user and ' \
           'the database authentication system' do
        find '#flash',
             text: _(
               'First admin user has been created. ' \
               'Default database authentication system has been configured.'
             )
      end

      step 'I click on login' do
        find('a.button,button', text: _('Login')).click
      end

      step 'the login form is displayed' do
        expect(current_path).to be == '/authenticator/db/login'
      end

      step 'I fill in the login of the created admin user' do
        fill_in 'login[username]', with: @login
      end

      step 'I fill in the password of the created admin user' do
        fill_in 'login[password]', with: @password
      end

      step 'I have been successfully logged in as the created admin user' do
        within '#topbar' do
          expect(page).to have_content @lastname
        end
      end

      step 'I see the admin section' do
        expect(current_path).to start_with '/admin'
      end

      step 'non-default database authentication system exists' do
        @db_auth_system = FactoryGirl.create(:authentication_system,
                                             class_name: 'DatabaseAuthentication',
                                             is_default: false)
      end

      step 'some other default authentication system exists' do
        @other_auth_system = \
          FactoryGirl.create(:authentication_system,
                             class_name: 'LDAPAuthentication',
                             is_default: true)
      end

      step 'the database authentication system has been set to default' do
        expect(@db_auth_system.reload.is_default).to be true
      end

      step 'the other authentication system is not default anymore' do
        expect(@other_auth_system.reload.is_default).to be false
      end
    end
  end
end

RSpec.configure do |config|
  config.include Manage::Spec::CreateFirstAdminUserSteps,
                 manage_create_first_admin_user: true
end
