module Procurement
  module FileUtilities
    def self.convert_file(filepath)
      if system("convert #{filepath} -resize '40x40' #{filepath}")
        filepath
      else
        raise 'convert: could not create thumbnail'
      end
    end

    def self.content_type(filepath)
      `file -b --mime-type #{filepath}`.sub("\n", '')
    end
  end
end
