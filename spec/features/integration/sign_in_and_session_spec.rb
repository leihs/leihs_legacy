require 'turnip_helper'

describe 'sign in and session' do
  describe 'the max lifetime of the session' do
    describe 'a signed in user will be signed out if the user_session expires' do
      it :works do
        @signed_in_user = FactoryGirl.create(:admin)
        visit root_path
        fill_in :email, with: @signed_in_user.email
        click_on _('Login')
        click_on _('Settings')
        page.execute_script %[ $(".navbar").remove() ]
        fill_in _('sessions_max_lifetime_secs'), with: 15
        click_on _('Save Settings')

        # we will get signed out me
        expect(page).to have_content @signed_in_user.lastname
        sleep 15
        visit current_path
        expect(page).not_to have_content @signed_in_user.lastname
      end
    end
  end
end
