module FileConversion
  def self.create_thumbnail(filepath)
    thumbnail_filepath = "#{filepath}.thumb"
    if system("convert #{filepath} -resize '100x100' #{thumbnail_filepath}")
      thumbnail_filepath
    else
      raise 'convert: could not create thumbnail'
    end
  end
end
