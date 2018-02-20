module RoomsDiff

  def get_rooms_diff
    # get_rooms_diff.html.haml
  end

  def post_rooms_diff
    require 'csv'

    values = []
    CSV.foreach(
      params[:csv_file].tempfile,
      col_sep: ',',
      quote_char: "\"",
      headers: :first_row) do |row|

      value = handle_row(row)
      values << value
    end

    values = values.compact

    items_with_rooms = Item.connection.exec_query(items_with_rooms_query).to_a

    invalid_items_with_rooms = items_with_rooms.select do |i|
      building = i['building_name']
      room = i['room_name']

      matches = values.select do |v|
        v[:liegenschaft] == building && v[:raumnummer] == room
      end

      matches.empty?
    end

    # invalid_items = Item.find(
    #   invalid_items_with_rooms.map { |i| i['item_id'] }
    # )
    #
    # objects = invalid_items.map(&:to_csv_array)
    # header = header_for_export(objects)
    #
    # export = Export.excel_string(
    #   header, objects, worksheet_name: _('Rooms Diff'))
    #
    # send_data \
    #   export,
    #   type: 'application/xlsx',
    #   disposition: \
    #     'filename=room_diff.xlsx'

    problematic_rooms = invalid_items_with_rooms.group_by do |i|
      [i['building_name'], i['room_name']]
    end.map do |k, v|
      {
        building_name: k[0],
        room_name: k[1],
        item_count: v.count,
        inventory_codes: v.map { |v| v['item_inventory_code'] }
      }
    end

    header = ["building_name", "room_name", "item_count", "inventory_codes"]
                .join(',')

    data = problematic_rooms.map do |v|
      inventory_codes = if v[:inventory_codes].count > 100
                          'more than 100'
                        else
                          v[:inventory_codes].join(',')
                        end
      [
        v[:building_name],
        v[:room_name],
        v[:item_count],
        inventory_codes
      ].map { |w| "\"#{w}\"" }.join(',')
    end

    csv_lines = [header].concat(data)

    # problematic_rooms_csv = invalid_items_with_rooms.uniq do |i|
    #   [i['building_name'], i['room_name']]
    # end.map do |i|
    #   {
    #     _('Building') => i['building_name'],
    #     _('Room') => i['room_name']
    #   }
    # end

    # header = header_for_export(problematic_rooms_csv)
    #
    # export = Export.excel_string(
    #   header, problematic_rooms_csv, worksheet_name: 'Problematic Rooms')

    send_data \
      csv_lines.join("\n"),
      type: 'application/csv',
      disposition: \
        'filename=problematic_rooms.csv'

    # post_rooms_diff.html.haml
  end

  private

  # def header_for_export(objects_for_export)
  #   if objects_for_export.empty?
  #     [_('No entries found')]
  #   else
  #     objects_for_export.flat_map(&:keys).uniq
  #   end
  # end

  def items_with_rooms_query
    <<-SQL
      select
        items.id as item_id,
        items.inventory_code as item_inventory_code,
        buildings.name as building_name,
        rooms.name as room_name
      from
        items,
        buildings,
        rooms
      where
        items.room_id = rooms.id
        and rooms.building_id = buildings.id
    SQL
  end

  def handle_row(row)
    liegenschaft = row['Liegenschaft']
    raumnummer = row['Raumnummer']

    return nil if liegenschaft.blank?
    return nil if raumnummer.blank?

    {
      liegenschaft: liegenschaft,
      raumnummer: raumnummer
    }
  end
end
