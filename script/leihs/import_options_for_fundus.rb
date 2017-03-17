# run with "rails runner -e production PATH_TO_THIS_FILE"
# WARNING: USE AT YOUR OWN RISK!!!

require_relative('logger')
require_relative('parse_csv')
require('pry')

csv_parser = CSVParser.new("#{File.dirname(__FILE__)}/import.txt")

ip = InventoryPool.find_by_name('Fundus-TdK')
last_inv_code = ip.options.map(&:inventory_code).compact.sort.last

i = Item.last_number(last_inv_code) + 1
csv_parser.for_each_row do |row|
  inv_code = "FUNO#{i}"
  log "#{inv_code}, #{row['Name']}, #{row['Price']}", :info, true
  begin
    Option.create(inventory_pool: ip,
                  inventory_code: inv_code,
                  product: row['Name'],
                  price: row['Price'])
    csv_parser.row_success!
    i = i + 1
  rescue => e
    log e.message, :error, true
  end
end
