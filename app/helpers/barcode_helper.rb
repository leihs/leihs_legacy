module BarcodeHelper

  require 'barby'
  require 'barby/barcode/code_128'
  require 'barby/outputter/png_outputter'

  def barcode_for_contract(contract, height = 25)
    png = \
      Barby::Code128B
      .new(" C #{contract.compact_id}")
      .to_png(height: Integer(height))
    "data:image/png;base64,#{Base64.strict_encode64(png)}"
  end

  def barcode_for_item(item, height = 25)
    png = \
      Barby::Code128B
      .new(item.inventory_code)
      .to_png(height: Integer(height))
    "data:image/png;base64,#{Base64.strict_encode64(png)}"
  end

end
