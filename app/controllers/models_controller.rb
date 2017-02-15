class ModelsController < ApplicationController

  before_action do
    require_role :customer
  end

  def image
    image = Model.find(id_param).image(params[:offset])

    if image and params[:size] == :thumb
      redirect_to get_image_thumbnail_path(image.id)
    elsif image
      redirect_to get_image_path(image.id)
    else
      empty_gif_pixel = \
        "R0lGODlhAQABAIAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==\n"
      send_data(Base64.decode64(empty_gif_pixel),
                type: 'image/gif',
                disposition: 'inline')
    end
  end

  private

  def id_param
    params.require(:id)
  end

end
