require_dependency 'procurement/application_controller'

module Procurement
  class CategoriesController < ApplicationController

    before_action do
      unless procurement_admin?
        # raise Errors::ForbiddenError
        flash.now[:error] = _('You are not authorized for this action.')
        render action: :root
      end
    end

    def index
      @categories = MainCategory.all
      respond_to do |format|
        format.html
        format.json { render json: @categories }
      end
    end

    def create
      errors = create_or_update_or_destroy

      if errors.empty?
        flash[:success] = _('Saved')
        head :ok
      else
        render json: errors, status: :internal_server_error
      end
    end

    private

    def create_or_update_or_destroy
      params.require(:main_categories).values.map do |param|
        if param[:id]
          main_category = Procurement::MainCategory.find(param[:id])
          handle_existing_category(main_category, param)
        else
          next if param[:name].blank?
          main_category = Procurement::MainCategory.new
          handle_new_category(main_category, param)
        end
        main_category.errors.full_messages
      end.flatten.compact
    end

    def handle_existing_category(main_category, param)
      if param.delete(:_destroy) == '1' or param[:name].blank?
        main_category.destroy
      else
        ApplicationRecord.transaction do
          image_delete = param.delete('image_delete')
          if image_delete == '1'
            main_category.destroy_image_with_thumbnail!
          end
          if file = param.delete('image')
            if main_category.image
              main_category.destroy_image_with_thumbnail!
            end
            create_image_with_thumbnail!(main_category, file)
          end
          main_category.assign_attributes(param)
          main_category.save!
        end
      end
    end

    def handle_new_category(main_category, param)
      ApplicationRecord.transaction do
        file = param.delete('image')
        main_category.assign_attributes(param)
        main_category.save!
        if file
          create_image_with_thumbnail!(main_category, file)
        end
      end
    end

    def create_image_with_thumbnail!(main_category, file)
      image = Image.create!(main_category_id: main_category.id,
                            content: Base64.encode64(file.read),
                            filename: file.original_filename,
                            metadata: \
                              MetadataExtractor.new(file.tempfile.path).to_hash,
                            size: file.size,
                            content_type: file.content_type)

      extension = File.extname(file.original_filename)
      basename = File.basename(file.original_filename, extension)
      thumbnail_filepath = Procurement::FileUtilities.convert_file(file.path)
      thumbnail_file = File.open(thumbnail_filepath)
      Image.create!(main_category_id: main_category.id,
                    content: Base64.encode64(thumbnail_file.read),
                    filename: "#{basename}_thumb#{extension}",
                    size: thumbnail_file.size,
                    metadata:  MetadataExtractor.new(thumbnail_filepath).to_hash,
                    parent_id: image.id,
                    content_type: file.content_type)
    end

  end
end
