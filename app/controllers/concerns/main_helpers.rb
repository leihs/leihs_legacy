module MainHelpers
  extend ActiveSupport::Concern

  included do
    require File.join(Rails.root, 'lib', 'authenticated_system.rb')
    include AuthenticatedSystem
    include AppSettings

    helper_method(:current_inventory_pool,
                  :current_managed_inventory_pools,
                  :admin?)

    # TODO: **20 optimize lib/role_requirement and refactor to backend
    def current_inventory_pool
      nil
    end

    def current_managed_inventory_pools
      current_user.inventory_pools.managed.sort
    end

    def add_visitor(user)
      session[:last_visitors] ||= []
      session[:last_visitors].delete([user.id, user.name])
      session[:last_visitors].delete_at(0) if session[:last_visitors].size > 4
      session[:last_visitors] << [user.id, user.name]
    end

    def set_gettext_locale
      gettext_language = if current_user
                           if params[:locale] # user requested change of his preferred language
                             new_user_language = Language.where(locale: params[:locale]).first
                             current_user.update(language: new_user_language)
                           end
                           current_user.language or Language.default_language
                         else
                           Language.default_language
                         end

      I18n.locale = gettext_language.locale.underscore.to_sym
    end

    def set_pagination_header(paginated_active_record,
                              disable_total_count: false,
                              custom_count: nil)
      headers['X-Pagination'] = {
        total_count: total_count(paginated_active_record,
                                 disable: disable_total_count,
                                 custom_count: custom_count),
        per_page: paginated_active_record.per_page,
        offset: paginated_active_record.offset
      }.to_json
    end

    ##################################################
    # ACL

    def not_authorized!(options = { redirect_path: nil })
      options[:redirect_path] ||= admin.inventory_pools_path
      msg = "You don't have appropriate permission to perform this operation."

      respond_to do |format|
        format.html do
          flash[:error] = msg
          redirect_to options[:redirect_path]
        end
        format.json { render plain: msg }
      end
    end

    ####### Helper Methods #######

    def admin?
      current_user && current_user.is_admin
    end

    def permit_params
      params.permit!
    end

    def total_count(paginated_active_record, disable: false, custom_count: nil)
      if disable
        nil
      elsif custom_count
        custom_count
      else
        paginated_active_record.total_entries
      end
    end

  end

  if Rails.env.production?
    def sign_in_path
      '/sign-in'
    end

    def sign_out_path
      '/sign-out'
    end
  end

end
