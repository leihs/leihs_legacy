module FileStorage
  def store_image_with_thumbnail!(file, model)
    ApplicationRecord.transaction(requires_new: true) do
      image = store_image!(file, model)

      extension = File.extname(file.original_filename)
      basename = File.basename(file.original_filename, extension)
      thumbnail_filepath = FileConversion.create_thumbnail(file.path)
      thumbnail_file = File.open(thumbnail_filepath)
      thumbnail = model.images.build(
        content: Base64.encode64(thumbnail_file.read),
        filename: "#{basename}_thumb#{extension}",
        size: thumbnail_file.size,
        thumbnail: true,
        metadata: MetadataExtractor.new(thumbnail_filepath).to_hash,
        parent_id: image.id,
        content_type: file.content_type
      )
      thumbnail.save!
      image
    end
  end

  def store_image!(file, model)
    image = model.images.build(
      content: Base64.encode64(file.read),
      filename: file.original_filename,
      size: file.size,
      metadata: MetadataExtractor.new(file.tempfile.path).to_hash,
      content_type: file.content_type
    )
    image.save!
    image
  end

  def store_attachment!(file, **opts)
    attachment = Attachment.new(
      content: Base64.encode64(file.read),
      filename: file.original_filename,
      size: file.size,
      metadata: MetadataExtractor.new(file.tempfile.path).to_hash,
      content_type: file.content_type,
      **opts
    )
    attachment.save!
  end
end
