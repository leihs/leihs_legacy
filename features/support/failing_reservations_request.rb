module FailingReservationsRequest
  mattr_accessor :pending_failures, default: 0
  mattr_accessor :requests, default: 0

  def index
    if params[:contract_ids].present? || params[:order_ids].present?
      FailingReservationsRequest.requests += 1
      if FailingReservationsRequest.pending_failures > 0
        FailingReservationsRequest.pending_failures -= 1
        return head(:internal_server_error)
      end
    end
    super
  end
end
Manage::ReservationsController.prepend FailingReservationsRequest

Before do
  FailingReservationsRequest.pending_failures = 0
  FailingReservationsRequest.requests = 0
end
