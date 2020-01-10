class MailsController < ApplicationController

  def send_received
    Order.find(params[:order_id]).send_received_notification
    head(:accepted)
  rescue => e
    Rails.logger.warn(e)
    render(status: 500, plain: e.message)
  end

end
