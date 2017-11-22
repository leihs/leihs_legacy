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
    @signed_in_user = User.find_by! login: login
    click_on _("Login")
    fill_in _("Username"), with: login
    fill_in _("Password"), with: password
    click_on _("Login")
    expect(page).to have_content @signed_in_user.lastname
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

end
