# This handles all errors/exceptions.

# What happens in Rails before get here:
# - Rails config: set the "expection handling rack app" to this controller,
#    see: <http://api.rubyonrails.org/classes/ActionDispatch/ShowExceptions.html>
# - If an exception happens from here on, a plain text fallback is used!
class ErrorsController < ActionController::Base

  # skip_before_action :authenticate_user!

  def show
    skip_authorization if defined?(skip_authorization)

    # get the expection and corresponding status code and response from Rails:
    exception = request.env['action_dispatch.exception']
    # these fall back to 500/'Internal Server Error' if nothing is specified:
    status = ActionDispatch::ExceptionWrapper.new(Rails.env, exception).status_code
    message = ActionDispatch::ExceptionWrapper
                .rescue_responses[exception.class.name]
                .to_s.titleize

    # get some details about the exception, with cleaned up backtrace paths:
    details = [flash[:error],
               exception.try(:message) || message, exception.try(:cause),
               exception.try(:backtrace).try(:first, 5)]
    details = clean_up_trace(details.flatten.compact.uniq)

    get = { code: status, message: message, details: details }
    respond_to do |format|
      format.json { render('errors', status: status, json: { error: get }) }
      format.html { render('errors', status: status, layout: false, locals: get) }
    end
  end

  private

  def clean_up_trace(lines)
    lines.map { |trace| trace.try(:remove, Regexp.new(Rails.root.to_s + '/')) }
  end
end
