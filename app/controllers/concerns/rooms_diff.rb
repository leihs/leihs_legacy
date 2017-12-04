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

    items_with_rooms_query = <<-SQL
      select
        items.id as item_id,
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

    items_with_rooms = Item.connection.exec_query(items_with_rooms_query).to_a

    invalid_items_with_rooms = items_with_rooms.select do |i|
      building = i['building_name']
      room = i['room_name']

      matches = values.select do |v|
        v[:liegenschaft] == building && v[:raumnummer] == room
      end

      !matches.empty?
    end

    invalid_items = Item.find(invalid_items_with_rooms.map { |i| i['item_id'] })

    objects = invalid_items.map(&:to_csv_array)
    header = header_for_export(objects)

    export = Export.excel_string(
      header, objects, worksheet_name: _('Rooms Diff'))

    send_data \
      export,
      type: 'application/xlsx',
      disposition: \
        'filename=room_diff.xlsx'

    # post_rooms_diff.html.haml
  end

  private

  def header_for_export(objects_for_export)
    if objects_for_export.empty?
      [_('No entries found')]
    else
      objects_for_export.flat_map(&:keys).uniq
    end
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
