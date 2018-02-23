module Spec
  module LoginSteps
    step 'I am :persona' do |persona|
      step 'I log out'
      @current_user = User.where(login: persona.downcase).first
      set_locale
      login_as_current_user
      set_current_inventory_pool
    end

    step 'I log out' do
      visit logout_path
      find('#flash')
    end

    [:customer, :group_manager, :lending_manager, :inventory_manager]
      .each do |role|
      step "I am logged in as #{role.to_s.sub('_', ' ')}" do
        ip = FactoryGirl.create(:inventory_pool)
        role == :customer ? @inventory_pool = ip : @current_inventory_pool = ip
        @current_user = @customer = \
          FactoryGirl.create(role, inventory_pool: ip)
        step 'I log out'
        set_locale
        login_as_current_user
      end
    end

    step 'I am logged in as admin' do
      @current_user = FactoryGirl.create(:admin)
      step 'I log out'
      set_locale
      login_as_current_user
    end

    step 'I am logged in as the user' do
      @current_user = @user
      step 'I log out'
      set_locale
      login_as_current_user
    end

    step 'I have the roles' do |table|
      user = @current_user
      ip = @current_inventory_pool || @inventory_pool
      fail unless user.present? && ip.present?
      table.headers.each do |role|
        next if AccessRight.find_by(user: user, inventory_pool: ip, role: role)
        if role == 'admin'
          user.update_attributes! is_admin: true
        else
          FactoryGirl.create(
            :access_right,
            user: user, inventory_pool: ip, role: role
          )
        end
      end
    end

    private

    def set_current_inventory_pool
      @current_inventory_pool = @current_user.inventory_pools.managed.first
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
