class AttachmentsController < ApplicationController
  def show
    attachment = Attachment.find(id_param)
    if attachment
      send_data \
        Base64.decode64(attachment.content.to_s),
        filename: attachment.filename,
        type: attachment.content_type,
        disposition: 'inline'
    else
      head :not_found and return
    end
  end

  private

  def id_param
    params.require(:id)
  end
end
