module WorkaroundRailsBug25198
  def deal_with_destroy_nested_attributes!(entity_params)
    if images_attrs = entity_params[:images_attributes]
      images_attrs.each_pair do |image_id, spec|
        next unless spec[:_destroy] == '1'
        thumbnails = Image.where(parent_id: image_id)
        thumbnails.each do |thumbnail|
          ActiveRecord::Base.connection.exec_delete <<-SQL
            DELETE FROM images WHERE id = '#{thumbnail.id}'
          SQL
        end

        ActiveRecord::Base.connection.exec_delete <<-SQL
          DELETE FROM images WHERE id = '#{UUIDTools::UUID.parse(image_id)}'
        SQL

        images_attrs.delete(image_id)
      end
    end
  end
end
