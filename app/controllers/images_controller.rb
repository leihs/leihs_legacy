class ImagesController < ApplicationController
  def show
    image = Image.find(image_id_param)
    send_data_or_render_not_found(image)
  end

  def thumbnail
    thumbnail = Image.find_by_parent_id(image_id_param)
    send_data_or_render_not_found(thumbnail)
  end

  private

  def send_data_or_render_not_found(image)
    if image and image.content
      send_data \
        Base64.decode64(image.content),
        filename: image.filename,
        type: image.content_type,
        disposition: 'inline'
    else
      head :not_found and return
    end
  end

  def image_id_param
    params.require(:id)
  end
end
