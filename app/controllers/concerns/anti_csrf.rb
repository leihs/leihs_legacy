module AntiCsrf
  extend ActiveSupport::Concern

  included do
    protect_from_forgery with: :exception

    before_action :get_and_set_global_csrf_token
    attr_reader :leihs_anti_csrf_token
    helper_method :leihs_anti_csrf_token

    # Used for logging out via `my` in production.
    def get_and_set_global_csrf_token
      @leihs_anti_csrf_token = cookies['leihs-anti-csrf-token']
    end
  end
end
