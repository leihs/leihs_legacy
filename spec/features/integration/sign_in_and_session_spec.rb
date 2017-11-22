require 'turnip_helper'

describe 'sign in and session' do

  def create_first_admin_user
    visit "/"
    expect(page).to have_content _('First admin user')
    fill_in _('Last name'), with: 'Admin'
    fill_in _('First name'), with: 'Adam'
    fill_in _('E-Mail'), with: 'admin@example.com'
    fill_in _("Login"), with: 'admin'
    fill_in "#{_('Password')} *", with: 'password'
    fill_in _("Password Confirmation"), with: 'password'
    click_on _("Save")
    expect(page).to have_content \
      _('First admin user has been created. ' +
        'Default database authentication system has been configured.')
    @fist_admin_user = User.find_by! login: 'admin'
  end

  def sign_in_as login, password
    sign_out
    visit '/'
    @signed_in_user = User.find_by! login: login
    click_on _("Login")
    fill_in _("Username"), with: login
    fill_in _("Password"), with: password
    click_on _("Login")
    expect(page).to have_content @signed_in_user.lastname
  end

  def sign_out
    visit "/"
    if @signed_in_user && page.has_content?(@signed_in_user.short_name)
      click_on @signed_in_user.short_name
      click_on _('Logout')
    end
    @signed_in_user = nil
  end

  describe 'the max lifetime of the session' do
    describe 'a signed in user will be signed out if the user_session expires' do
      it :works do
        create_first_admin_user
        sign_in_as 'admin', 'password'

        click_on _('Settings')
        fill_in _("sessions_max_lifetime_secs"), with: 15
        page.execute_script %[ $(".navbar").remove() ]
        click_on _('Save Settings')

        # we will get sigend out me
        expect(page).to have_content @signed_in_user.lastname
        sleep 15
        visit current_path
        expect(page).not_to have_content @signed_in_user.lastname
      end
    end
  end


  describe 'uniqueness setting of the user_session' do

    context 'by default enabled sessions_force_uniqueness' do
      describe 'my previous session will be removed if sign in again' do
        it :works do
          create_first_admin_user
          sign_in_as 'admin', 'password'

          # there is exactly one session
          sessions = UserSession.where(user_id: @signed_in_user.id).to_a
          expect(sessions.count).to be== 1

          click_on _("Settings")
          check _('sessions_force_uniqueness')
          page.execute_script %[ $(".navbar").remove() ]
          click_on _('Save Settings')

          # after signing out and signing in there is again exactly one new(!) session
          sign_in_as 'admin', 'password'
          new_sessions = UserSession.where(user_id: @signed_in_user.id).to_a
          expect(new_sessions.count).to be== 1
          expect(new_sessions.first.id).not_to be== sessions.first.id
        end
      end
    end

    context 'disabled setting sessions_force_uniqueness' do
      describe 'my previous session will persist if sign in again' do
        it :works do
          create_first_admin_user
          sign_in_as 'admin', 'password'

          # there is exactly one session
          sessions = UserSession.where(user_id: @signed_in_user.id).to_a
          expect(sessions.count).to be== 1

          click_on _("Settings")
          uncheck _('sessions_force_uniqueness')
          page.execute_script %[ $(".navbar").remove() ]
          click_on _('Save Settings')

          # we need to resort to the following because a normal sign out
          # would also destroy the @user_session
          Capybara.current_session.driver.browser.manage.delete_all_cookies

          # after signing in the previous session is still arround
          sign_in_as 'admin', 'password'
          new_sessions = UserSession.where(user_id: @signed_in_user.id).to_a
          expect(new_sessions.count).to be== 2
          expect(new_sessions.map(&:id)).to include sessions.first.id
        end
      end
    end
  end
end
