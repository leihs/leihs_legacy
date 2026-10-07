module FailingContractsSearchPage
  mattr_accessor :pending_failures, default: 0
  mattr_accessor :requests, default: 0

  def index
    if params[:global_contracts_search] == 'true' &&
        params[:disable_total_count] == 'true' &&
        params[:page].to_s == '1'
      FailingContractsSearchPage.requests += 1
      if FailingContractsSearchPage.pending_failures > 0
        FailingContractsSearchPage.pending_failures -= 1
        return head(:internal_server_error)
      end
    end
    super
  end
end
Manage::ContractsController.prepend FailingContractsSearchPage

Before do
  FailingContractsSearchPage.pending_failures = 0
  FailingContractsSearchPage.requests = 0
end
