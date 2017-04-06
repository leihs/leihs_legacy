module Spec
  module LoginSteps
    step 'I am :persona' do |persona|
      step 'I log out'
      set_current_user(persona)
      set_locale
      login_as_current_user
      set_current_inventory_pool
    end

    step 'I log out' do
      visit logout_path
      find('#flash')
    end

    private

    def set_current_inventory_pool
      @current_inventory_pool = @current_user.inventory_pools.managed.first
    end

    def set_current_user(persona)
      @current_user = User.where(login: persona.downcase).first
    end

    def set_locale
      I18n.locale = if @current_user.language
                      @current_user.language.locale_name.to_sym
                    else
                      Language.default_language
                    end
    end

    def login_as_current_user
      click_on _('Login')
      fill_in _('Username'), with: @current_user.login
      fill_in _('Password'), with: 'password'
      click_on _('Login')
    end
  end
end
