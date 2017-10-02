# add custom error classes
module Errors
  class UnauthorizedError < StandardError
    # If the request requires a login, but user is not logged in.
  end

  class ForbiddenError < StandardError
    # If user is logged in, but access is denied.
  end
end

# handle all error pages inside the app with a custom controller
# to develop/debug error pages `export RAILS_DEBUG_ERRORS=1`
Rails.application.configure do
  config.show_exceptions = true
  config.exceptions_app = ->(env) { ErrorsController.action(:show).call(env) }

  if Rails.env.development? && ENV['RAILS_DEBUG_ERRORS'].nil?
    config.consider_all_requests_local = true
  else
    config.consider_all_requests_local = false
  end
end

# add http mappings for our custom error classes
errors_to_http_status = {
  'Pundit::NotAuthorizedError' => :forbidden # 403
}
Rails.application.config.before_configuration do
  ActionDispatch::ExceptionWrapper.rescue_responses.merge!(errors_to_http_status)
end
