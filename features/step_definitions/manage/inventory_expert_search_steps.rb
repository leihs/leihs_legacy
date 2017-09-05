# encoding: utf-8

def login_as_user(user, password)
  click_on _('Login')
  fill_in _('Username'), with: user.login
  fill_in _('Password'), with: 'password'
  click_on _('Login')
end

def create_user
  FactoryGirl.create(:user)
end

def open_login
  visit logout_path
end

def create_inventory_pool
  FactoryGirl.create(:inventory_pool)
end

def enable_manager_for_inventory_pool(user, inventory_pool)
  FactoryGirl.create(:access_right, user: user, inventory_pool: inventory_pool, role: 'inventory_manager')
end

def click_expert_search
  find('.navigation-tab-item', text: _('Expert Search')).click
end

def create_field(f)
  field = Field.new(id: f[:id], data: f[:data], active: f[:active], position: f[:position])
  field.save!
  field
end

def shared_prepare_data
  user = create_user
  inventory_pool = create_inventory_pool
  enable_manager_for_inventory_pool(user, inventory_pool)
  {
    user: user,
    inventory_pool: inventory_pool
  }
end

def shared_open_expert_search(data)
  open_login
  login_as_user(data[:user], 'password')
  click_expert_search
end

def delete_all_fields
  Field.unscoped.all.destroy_all
end

def create_item(inventory_pool)
  FactoryGirl.create(:item, inventory_pool: inventory_pool)
end

def check_result(expected_items)
  within('#inventory') do
    expect(page).to have_selector('.line', count: expected_items.length)
    expected_items.each do |item|
      find("div[data-item-id='#{item.id}']")
    end
  end
end

def step_field_generic(field_config, fill_item_1, fill_field)
  data = shared_prepare_data
  delete_all_fields
  field = create_field(field_config.())
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])
  fill_item_1.(item_1, item_2) if fill_item_1
  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field)
  fill_field.(field, item_1)
  check_result([item_1])
end

def step_field_inventory_code
  step_field_generic(
    -> { field_config_inventory_code },
    nil,
    -> (field, item_1) { fill_type_input(field, item_1.inventory_code) }
  )
end

def step_field_model_id
  step_field_generic(
    -> { field_config_model_id },
    nil,
    -> (field, item_1) { fill_type_search_autocomplete(field, item_1.model.product) }
  )
end

def step_field_serial_number
  step_field_generic(
    -> { field_config_serial_number },
    nil,
    -> (field, item_1) { fill_type_input(field, item_1.serial_number) }
  )
end

def step_field_properties_mac_address
  step_field_generic(
    -> { field_config_properties_mac_address },
    -> (item_1, item_2) do
      item_1.properties['mac_address'] = 'test-mac-address'
      item_1.save!
      item_1.reload
    end,
    -> (field, item_1) { fill_type_input(field, item_1.properties['mac_address']) }
  )
end

def step_field_properties_imei_number
  step_field_generic(
    -> { field_config_properties_imei_number },
    -> (item_1, item_2) do
      item_1.properties['imei_number'] = 'test-imei-number'
      item_1.save!
      item_1.reload
    end,
    -> (field, item_1) { fill_type_input(field, item_1.properties['imei_number']) }
  )
end

def step_field_name
  step_field_generic(
    -> { field_config_name },
    -> (item_1, item_2) do
      item_1.name = 'test-name'
      item_1.save!
      item_1.reload
    end,
    -> (field, item_1) { fill_type_input(field, item_1.name) }
  )
end

def step_field_note
  step_field_generic(
    -> { field_config_note },
    -> (item_1, item_2) do
      item_1.note = 'test-note'
      item_1.save!
      item_1.reload
    end,
    -> (field, item_1) { fill_type_textarea(field, item_1.note) }
  )
end

def step_field_retired_and_retired_reason
  data = shared_prepare_data
  delete_all_fields
  field_retired = create_field(field_config_retired)
  field_retired_reason = create_field(field_config_retired_reason)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])

  item_1.retired = Date.parse('2018-06-27')
  item_1.retired_reason = 'test-retired-reason'
  item_1.save!
  item_1.reload

  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field_retired)
  check_result([item_2])

  fill_type_dropdown(field_retired, 'Yes')
  fill_type_textarea(field_retired_reason, 'test-retired-reason')
  check_result([item_1])
end

def step_field_is_broken
  data = shared_prepare_data
  delete_all_fields
  field = create_field(field_config_is_broken)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])
  item_1.is_broken = true
  item_1.save!
  item_1.reload

  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field)
  check_result([item_2])

  fill_type_radio(field, 'Broken')
  check_result([item_1])
end

def step_field_is_incomplete
  data = shared_prepare_data
  delete_all_fields
  field = create_field(field_config_is_incomplete)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])
  item_1.is_incomplete = true
  item_1.save!
  item_1.reload

  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field)
  check_result([item_2])

  fill_type_radio(field, 'Incomplete')
  check_result([item_1])
end

def step_field_is_borrowable
  data = shared_prepare_data
  delete_all_fields
  field = create_field(field_config_is_borrowable)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])
  item_1.is_borrowable = true
  item_1.save!
  item_1.reload
  item_2.is_borrowable = false
  item_2.save!
  item_2.reload

  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field)
  check_result([item_2])

  fill_type_radio(field, 'OK')
  check_result([item_1])
end

def step_field_status_note
  step_field_generic(
    -> { field_config_status_note },
    -> (item_1, item_2) do
      item_1.status_note = 'test-status-note'
      item_1.save!
      item_1.reload
    end,
    -> (field, item_1) { fill_type_textarea(field, item_1.status_note) }
  )
end

def step_fields_building_id_and_room_id
  data = shared_prepare_data
  delete_all_fields
  field_building_id = create_field(field_config_building_id)
  field_room_id = create_field(field_config_room_id)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])

  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field_building_id)

  fill_type_search_autocomplete(field_building_id, item_1.room.building.name)
  check_result([item_1])
  fill_type_search_autocomplete(field_room_id, item_1.room.name)
  check_result([item_1])
end

def step_field_shelf
  step_field_generic(
    -> { field_config_shelf },
    -> (item_1, item_2) do
      item_1.shelf = 'test-shelf'
      item_1.save!
      item_1.reload
    end,
    -> (field, item_1) { fill_type_input(field, item_1.shelf) }
  )
end

def step_field_is_inventory_relevant
  data = shared_prepare_data
  delete_all_fields
  field = create_field(field_config_is_inventory_relevant)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])
  item_1.is_inventory_relevant = false
  item_1.save!
  item_1.reload

  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field)
  check_result([item_2])
  fill_type_dropdown(field, 'No')
  check_result([item_1])
end

def step_field_owner_id
  step_field_generic(
    -> { field_config_owner_id },
    nil,
    -> (field, item_1) { fill_type_search_autocomplete(field, item_1.owner.name) }
  )
end

def step_field_last_check
  data = shared_prepare_data
  delete_all_fields
  field = create_field(field_config_last_check)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])

  item_1.last_check = Date.parse('25.03.2016')
  item_1.save!
  item_1.reload

  item_2.last_check = Date.parse('10.06.2016')
  item_2.save!
  item_2.reload

  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field)
  check_result([item_1, item_2])

  fill_type_date(:from, field, '20.03.2016')
  fill_type_date(:to, field, '30.03.2016')

  check_result([item_1])

  fill_type_date(:from, field, '30.03.2016')
  fill_type_date(:to, field, '10.01.2017')

  check_result([item_2])
end

def step_field_inventory_pool_id
  data = shared_prepare_data
  delete_all_fields
  field = create_field(field_config_inventory_pool_id)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])
  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field)
  fill_type_search_autocomplete(field, item_1.inventory_pool.name)
  check_result([item_1, item_2])
end

def step_field_responsible
  step_field_generic(
    -> { field_config_responsible },
    -> (item_1, item_2) do
      item_1.responsible = 'test-responsible'
      item_1.save!
      item_1.reload
    end,
    -> (field, item_1) { fill_type_input(field, item_1.responsible) }
  )
end

def step_field_price
  data = shared_prepare_data
  delete_all_fields
  field = create_field(field_config_price)
  item_1 = create_item(data[:inventory_pool])
  item_2 = create_item(data[:inventory_pool])

  item_1.price = 300.0
  item_1.save!
  item_1.reload
  item_2.price = 400.0
  item_2.save!
  item_2.reload

  shared_open_expert_search(data)
  check_result([item_1, item_2])
  select_field(field)

  fill_type_currency(:min, field, '100')
  fill_type_currency(:max, field, '350')

  check_result([item_1])

  fill_type_currency(:max, field, '500')
  check_result([item_1, item_2])

  fill_type_currency(:min, field, '350')
  check_result([item_2])
end

def select_field(field)
  label = field.data['label']
  find('#field-input').set(label)
  find('ul.ui-autocomplete').find('li.ui-menu-item').click
end

def find_field_box(field)
  find('#field-selection').find("div##{field.id}")
end

def fill_type_input(field, text)
  find_field_box(field).find('input').set(text)
end

def fill_type_dropdown(field, text)
  find_field_box(field).find('select').select(text)
end

def fill_type_textarea(field, text)
  find_field_box(field).find('textarea').set(text)
end

def fill_type_radio(field, text)
  find_field_box(field).find('span', text: text).click
end

def fill_type_search_autocomplete(field, text)
  find_field_box(field).find('input').set(text)
  find_field_box(field).find('.ui-menu-item', text: text).click
end

def fill_type_date(fromTo, field, text_date)
  label = \
    if fromTo == :from
      'von'
    elsif fromTo == :to
      'bis'
    else
      throw 'Unexpected from/to: ' + fromTo.to_s
    end
  find_field_box(field).find('div.col1of2[data-type=value]').find('div', text: label).find('input').set(text_date)
end

def fill_type_currency(minMax, field, text_value)
  label = \
    if minMax == :min
      'min'
    elsif minMax == :max
      'max'
    else
      throw 'Unexpected from/to: ' + fromTo.to_s
    end
  find_field_box(field).find('div.col1of2[data-type=value]').find('div', text: label).find('input').set(text_value)
end

Then(/^Step Field Inventory Code$/) do
  step_field_inventory_code
end

Then(/^Step Field Model Id$/) do
  step_field_model_id
end

Then(/^Step Field Serial Number$/) do
  step_field_serial_number
end

Then(/^Step Field Properties Mac Address$/) do
  step_field_properties_mac_address
end

Then(/^Step Field Properties Imei Number$/) do
  step_field_properties_imei_number
end

Then(/^Step Field Name$/) do
  step_field_name
end

Then(/^Step Field Note$/) do
  step_field_note
end

Then(/^Step Fields Retired and Retired Reason$/) do
  step_field_retired_and_retired_reason
end

Then(/^Step Field Is Broken$/) do
  step_field_is_broken
end

Then(/^Step Field Is Incomplete$/) do
  step_field_is_incomplete
end

Then(/^Step Field Is Borrowable$/) do
  step_field_is_borrowable
end

Then(/^Step Field Status Note$/) do
  step_field_status_note
end

Then(/^Step Fields Building Id and Room Id$/) do
  step_fields_building_id_and_room_id
end

Then(/^Step Field Shelf$/) do
  step_field_shelf
end

Then(/^Step Field Is Inventory Relevant$/) do
  step_field_is_inventory_relevant
end

Then(/^Step Field Owner Id$/) do
  step_field_owner_id
end

Then(/^Step Field Last Check$/) do
  step_field_last_check
end

Then(/^Step Field Inventory Pool Id$/) do
  step_field_inventory_pool_id
end

Then(/^Step Field Responsible$/) do
  step_field_responsible
end

Then(/^Step Field Price$/) do
  step_field_price
end

def field_config_inventory_code
  {
     "id":"inventory_code",
     "data":{
        "label":"Inventory Code",
        "attribute":"inventory_code",
        "required":true,
        "permissions":{
           "role":"inventory_manager",
           "owner":true
        },
        "type":"text",
        "group":nil,
        "forPackage":true
     },
     "active":true,
     "position":1
  }
end

def field_config_model_id
  {
     "id":"model_id",
     "data":{
        "label":"Model",
        "attribute":[
           "model",
           "id"
        ],
        "item_value_label":[
           "model",
           "product"
        ],
        "item_value_label_ext":[
           "model",
           "version"
        ],
        "form_name":"model_id",
        "required":true,
        "type":"autocomplete-search",
        "target_type":"item",
        "search_path":"models",
        "search_attr":"search_term",
        "value_attr":"id",
        "display_attr":"product",
        "display_attr_ext":"version",
        "group":nil
     },
     "active":true,
     "position":2
  }
end

def field_config_software_model_id
  {
     "id":"software_model_id",
     "data":{
        "label":"Software",
        "attribute":[
           "model",
           "id"
        ],
        "item_value_label":[
           "model",
           "product"
        ],
        "item_value_label_ext":[
           "model",
           "version"
        ],
        "form_name":"model_id",
        "required":true,
        "type":"autocomplete-search",
        "target_type":"license",
        "search_path":"software",
        "search_attr":"search_term",
        "value_attr":"id",
        "display_attr":"product",
        "display_attr_ext":"version",
        "group":nil
     },
     "active":true,
     "position":3
  }
end

def field_config_serial_number
  {
     "id":"serial_number",
     "data":{
        "label":"Serial Number",
        "attribute":"serial_number",
        "permissions":{
           "role":"lending_manager",
           "owner":true
        },
        "type":"text",
        "group":"General Information"
     },
     "active":true,
     "position":4
  }
end

def field_config_properties_mac_address
  {
     "id":"properties_mac_address",
     "data":{
        "label":"MAC-Address",
        "attribute":[
           "properties",
           "mac_address"
        ],
        "permissions":{
           "role":"lending_manager",
           "owner":true
        },
        "type":"text",
        "target_type":"item",
        "group":"General Information"
     },
     "active":true,
     "position":5
  }
end

def field_config_properties_imei_number
  {
     "id":"properties_imei_number",
     "data":{
        "label":"IMEI-Number",
        "attribute":[
           "properties",
           "imei_number"
        ],
        "permissions":{
           "role":"lending_manager",
           "owner":true
        },
        "type":"text",
        "target_type":"item",
        "group":"General Information"
     },
     "active":true,
     "position":6
  }
end

def field_config_name
  {
     "id":"name",
     "data":{
        "label":"Name",
        "attribute":"name",
        "type":"text",
        "target_type":"item",
        "group":"General Information",
        "forPackage":true
     },
     "active":true,
     "position":7
  }
end

def field_config_note
  {
     "id":"note",
     "data":{
        "label":"Note",
        "attribute":"note",
        "type":"textarea",
        "group":"General Information",
        "forPackage":true
     },
     "active":true,
     "position":8
  }
end

def field_config_retired
  {
     "id":"retired",
     "data":{
        "label":"Retirement",
        "attribute":"retired",
        "type":"select",
        "permissions":{
           "role":"lending_manager",
           "owner":true
        },
        "values":[
           {
              "label":"No",
              "value":false
           },
           {
              "label":"Yes",
              "value":true
           }
        ],
        "default":false,
        "group":"Status"
     },
     "active":true,
     "position":9
  }
end

def field_config_retired_reason
  {
     "id":"retired_reason",
     "data":{
        "label":"Reason for Retirement",
        "attribute":"retired_reason",
        "type":"textarea",
        "required":true,
        "permissions":{
           "role":"lending_manager",
           "owner":true
        },
        "visibility_dependency_field_id":"retired",
        "visibility_dependency_value":"true",
        "group":"Status"
     },
     "active":true,
     "position":10
  }
end

def field_config_is_broken
  {
     "id":"is_broken",
     "data":{
        "label":"Working order",
        "attribute":"is_broken",
        "type":"radio",
        "target_type":"item",
        "values":[
           {
              "label":"OK",
              "value":false
           },
           {
              "label":"Broken",
              "value":true
           }
        ],
        "default":false,
        "group":"Status",
        "forPackage":true
     },
     "active":true,
     "position":11
  }
end

def field_config_is_incomplete
  {
     "id":"is_incomplete",
     "data":{
        "label":"Completeness",
        "attribute":"is_incomplete",
        "type":"radio",
        "target_type":"item",
        "values":[
           {
              "label":"OK",
              "value":false
           },
           {
              "label":"Incomplete",
              "value":true
           }
        ],
        "default":false,
        "group":"Status",
        "forPackage":true
     },
     "active":true,
     "position":12
  }
end

def field_config_is_borrowable
  {
     "id":"is_borrowable",
     "data":{
        "label":"Borrowable",
        "attribute":"is_borrowable",
        "type":"radio",
        "values":[
           {
              "label":"OK",
              "value":true
           },
           {
              "label":"Unborrowable",
              "value":false
           }
        ],
        "default":false,
        "group":"Status",
        "forPackage":true
     },
     "active":true,
     "position":13
  }
end

def field_config_status_note
  {
     "id":"status_note",
     "data":{
        "label":"Status note",
        "attribute":"status_note",
        "type":"textarea",
        "target_type":"item",
        "group":"Status",
        "forPackage":true
     },
     "active":true,
     "position":14
  }
end

def field_config_building_id
  {
     "id":"building_id",
     "data":{
        "label":"Building",
        "attribute":[
           "room",
           "building_id"
        ],
        "required":true,
        "exclude_from_submit":true,
        "type":"autocomplete",
        "target_type":"item",
        "values":"all_buildings",
        "group":"Location",
        "forPackage":true
     },
     "active":true,
     "position":15
  }
end

def field_config_room_id
  {
     "id":"room_id",
     "data":{
        "label":"Room",
        "attribute":"room_id",
        "required":true,
        "type":"autocomplete",
        "target_type":"item",
        "values_dependency_field_id":"building_id",
        "values_url":"/manage/rooms.json?building_id=$$$parent_value$$$",
        "values_label_method":"to_s",
        "group":"Location",
        "forPackage":true
     },
     "active":true,
     "position":16
  }
end

def field_config_shelf
  {
     "id":"shelf",
     "data":{
        "label":"Shelf",
        "attribute":"shelf",
        "type":"text",
        "target_type":"item",
        "group":"Location",
        "forPackage":true
     },
     "active":true,
     "position":17
  }
end

def field_config_is_inventory_relevant
  {
     "id":"is_inventory_relevant",
     "data":{
        "label":"Relevant for inventory",
        "attribute":"is_inventory_relevant",
        "type":"select",
        "target_type":"item",
        "permissions":{
           "role":"inventory_manager",
           "owner":true
        },
        "values":[
           {
              "label":"No",
              "value":false
           },
           {
              "label":"Yes",
              "value":true
           }
        ],
        "default":true,
        "group":"Inventory",
        "forPackage":true
     },
     "active":true,
     "position":18
  }
end

def field_config_owner_id
  {
     "id":"owner_id",
     "data":{
        "label":"Owner",
        "attribute":[
           "owner",
           "id"
        ],
        "type":"autocomplete",
        "permissions":{
           "role":"inventory_manager",
           "owner":true
        },
        "values":"all_inventory_pools",
        "group":"Inventory"
     },
     "active":true,
     "position":19
  }
end

def field_config_last_check
  {
     "id":"last_check",
     "data":{
        "label":"Last Checked",
        "attribute":"last_check",
        "permissions":{
           "role":"lending_manager",
           "owner":true
        },
        "default":"today",
        "type":"date",
        "target_type":"item",
        "group":"Inventory",
        "forPackage":true
     },
     "active":true,
     "position":20
  }
end

def field_config_inventory_pool_id
  {
     "id":"inventory_pool_id",
     "data":{
        "label":"Responsible department",
        "attribute":[
           "inventory_pool",
           "id"
        ],
        "type":"autocomplete",
        "values":"all_inventory_pools",
        "permissions":{
           "role":"inventory_manager",
           "owner":true
        },
        "group":"Inventory",
        "forPackage":true
     },
     "active":true,
     "position":21
  }
end

def field_config_responsible
  {
     "id":"responsible",
     "data":{
        "label":"Responsible person",
        "attribute":"responsible",
        "permissions":{
           "role":"lending_manager",
           "owner":true
        },
        "type":"text",
        "target_type":"item",
        "group":"Inventory",
        "forPackage":true
     },
     "active":true,
     "position":22
   }
end

def field_config_price
  {
     "id":"price",
     "data":{
        "label":"Initial Price",
        "attribute":"price",
        "permissions":{
           "role":"lending_manager",
           "owner":true
        },
        "type":"text",
        "currency":true,
        "group":"Invoice Information",
        "forPackage":true
     },
     "active":true,
     "position":28
  }
end

def fields_config
  [
    field_config_inventory_code,
    field_config_model_id,
    field_config_software_model_id,
    field_config_serial_number,
    field_config_properties_mac_address,
    field_config_properties_imei_number,
    field_config_note,
    field_config_retired,
    field_config_retired_reason,
    field_config_is_broken,
    field_config_is_incomplete,
    field_config_is_borrowable,
    field_config_status_note,
    field_config_building_id,
    field_config_room_id,
    field_config_shelf,
    field_config_is_inventory_relevant,
    field_config_owner_id,
    field_config_last_check,
    field_config_inventory_pool_id,
    field_config_responsible,
     {
        "id":"user_name",
        "data":{
           "label":"User/Typical usage",
           "attribute":"user_name",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "type":"text",
           "target_type":"item",
           "group":"Inventory",
           "forPackage":true
        },
        "active":true,
        "position":23
     },
     {
        "id":"properties_reference",
        "data":{
           "label":"Reference",
           "attribute":[
              "properties",
              "reference"
           ],
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "required":true,
           "values":[
              {
                 "label":"Running Account",
                 "value":"invoice"
              },
              {
                 "label":"Investment",
                 "value":"investment"
              }
           ],
           "default":"invoice",
           "type":"radio",
           "group":"Invoice Information"
        },
        "active":true,
        "position":24
     },
     {
        "id":"properties_project_number",
        "data":{
           "label":"Project Number",
           "attribute":[
              "properties",
              "project_number"
           ],
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "type":"text",
           "required":true,
           "visibility_dependency_field_id":"properties_reference",
           "visibility_dependency_value":"investment",
           "group":"Invoice Information"
        },
        "active":true,
        "position":25
     },
     {
        "id":"invoice_number",
        "data":{
           "label":"Invoice Number",
           "attribute":"invoice_number",
           "permissions":{
              "role":"lending_manager",
              "owner":true
           },
           "type":"text",
           "target_type":"item",
           "group":"Invoice Information"
        },
        "active":true,
        "position":26
     },
     {
        "id":"invoice_date",
        "data":{
           "label":"Invoice Date",
           "attribute":"invoice_date",
           "permissions":{
              "role":"lending_manager",
              "owner":true
           },
           "type":"date",
           "group":"Invoice Information"
        },
        "active":true,
        "position":27
     },
     field_config_price,
     {
        "id":"supplier_id",
        "data":{
           "label":"Supplier",
           "attribute":[
              "supplier",
              "id"
           ],
           "type":"autocomplete",
           "extensible":true,
           "extended_key":[
              "supplier",
              "name"
           ],
           "permissions":{
              "role":"lending_manager",
              "owner":true
           },
           "values":"all_suppliers",
           "group":"Invoice Information"
        },
        "active":true,
        "position":29
     },
     {
        "id":"properties_warranty_expiration",
        "data":{
           "label":"Warranty expiration",
           "attribute":[
              "properties",
              "warranty_expiration"
           ],
           "permissions":{
              "role":"lending_manager",
              "owner":true
           },
           "type":"date",
           "target_type":"item",
           "group":"Invoice Information"
        },
        "active":true,
        "position":30
     },
     {
        "id":"properties_contract_expiration",
        "data":{
           "label":"Contract expiration",
           "attribute":[
              "properties",
              "contract_expiration"
           ],
           "permissions":{
              "role":"lending_manager",
              "owner":true
           },
           "type":"date",
           "target_type":"item",
           "group":"Invoice Information"
        },
        "active":true,
        "position":31
     },
     {
        "id":"properties_activation_type",
        "data":{
           "label":"Activation Type",
           "attribute":[
              "properties",
              "activation_type"
           ],
           "type":"select",
           "target_type":"license",
           "values":[
              {
                 "label":"None",
                 "value":"none"
              },
              {
                 "label":"Dongle",
                 "value":"dongle"
              },
              {
                 "label":"Serial Number",
                 "value":"serial_number"
              },
              {
                 "label":"License Server",
                 "value":"license_server"
              },
              {
                 "label":"Challenge Response/System ID",
                 "value":"challenge_response"
              }
           ],
           "default":"none",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"General Information"
        },
        "active":true,
        "position":32
     },
     {
        "id":"properties_dongle_id",
        "data":{
           "label":"Dongle ID",
           "attribute":[
              "properties",
              "dongle_id"
           ],
           "type":"text",
           "target_type":"license",
           "required":true,
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "visibility_dependency_field_id":"properties_activation_type",
           "visibility_dependency_value":"dongle",
           "group":"General Information"
        },
        "active":true,
        "position":33
     },
     {
        "id":"properties_license_type",
        "data":{
           "label":"License Type",
           "attribute":[
              "properties",
              "license_type"
           ],
           "type":"select",
           "target_type":"license",
           "values":[
              {
                 "label":"Free",
                 "value":"free"
              },
              {
                 "label":"Single Workplace",
                 "value":"single_workplace"
              },
              {
                 "label":"Multiple Workplace",
                 "value":"multiple_workplace"
              },
              {
                 "label":"Site License",
                 "value":"site_license"
              },
              {
                 "label":"Concurrent",
                 "value":"concurrent"
              }
           ],
           "default":"free",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"General Information"
        },
        "active":true,
        "position":34
     },
     {
        "id":"properties_total_quantity",
        "data":{
           "label":"Total quantity",
           "attribute":[
              "properties",
              "total_quantity"
           ],
           "type":"text",
           "target_type":"license",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "visibility_dependency_field_id":"properties_license_type",
           "visibility_dependency_value":[
              "multiple_workplace",
              "site_license",
              "concurrent"
           ],
           "group":"General Information"
        },
        "active":true,
        "position":35
     },
     {
        "id":"properties_quantity_allocations",
        "data":{
           "label":"Quantity allocations",
           "attribute":[
              "properties",
              "quantity_allocations"
           ],
           "type":"composite",
           "target_type":"license",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "visibility_dependency_field_id":"properties_total_quantity",
           "data_dependency_field_id":"properties_total_quantity",
           "group":"General Information"
        },
        "active":true,
        "position":36
     },
     {
        "id":"properties_operating_system",
        "data":{
           "label":"Operating System",
           "attribute":[
              "properties",
              "operating_system"
           ],
           "type":"checkbox",
           "target_type":"license",
           "values":[
              {
                 "label":"Windows",
                 "value":"windows"
              },
              {
                 "label":"Mac OS X",
                 "value":"mac_os_x"
              },
              {
                 "label":"Linux",
                 "value":"linux"
              },
              {
                 "label":"iOS",
                 "value":"ios"
              }
           ],
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"General Information"
        },
        "active":true,
        "position":37
     },
     {
        "id":"properties_installation",
        "data":{
           "label":"Installation",
           "attribute":[
              "properties",
              "installation"
           ],
           "type":"checkbox",
           "target_type":"license",
           "values":[
              {
                 "label":"Citrix",
                 "value":"citrix"
              },
              {
                 "label":"Local",
                 "value":"local"
              },
              {
                 "label":"Web",
                 "value":"web"
              }
           ],
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"General Information"
        },
        "active":true,
        "position":38
     },
     {
        "id":"properties_license_expiration",
        "data":{
           "label":"License expiration",
           "attribute":[
              "properties",
              "license_expiration"
           ],
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "type":"date",
           "target_type":"license",
           "group":"General Information"
        },
        "active":true,
        "position":39
     },
     {
        "id":"properties_maintenance_contract",
        "data":{
           "label":"Maintenance contract",
           "attribute":[
              "properties",
              "maintenance_contract"
           ],
           "type":"select",
           "target_type":"license",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "values":[
              {
                 "label":"No",
                 "value":"false"
              },
              {
                 "label":"Yes",
                 "value":"true"
              }
           ],
           "default":"false",
           "group":"Maintenance"
        },
        "active":true,
        "position":40
     },
     {
        "id":"properties_maintenance_expiration",
        "data":{
           "label":"Maintenance expiration",
           "attribute":[
              "properties",
              "maintenance_expiration"
           ],
           "type":"date",
           "target_type":"license",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "visibility_dependency_field_id":"properties_maintenance_contract",
           "visibility_dependency_value":"true",
           "group":"Maintenance"
        },
        "active":true,
        "position":41
     },
     {
        "id":"properties_maintenance_currency",
        "data":{
           "label":"Currency",
           "attribute":[
              "properties",
              "maintenance_currency"
           ],
           "type":"select",
           "values":"all_currencies",
           "default":"CHF",
           "target_type":"license",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "visibility_dependency_field_id":"properties_maintenance_expiration",
           "group":"Maintenance"
        },
        "active":true,
        "position":42
     },
     {
        "id":"properties_maintenance_price",
        "data":{
           "label":"Price",
           "attribute":[
              "properties",
              "maintenance_price"
           ],
           "type":"text",
           "currency":true,
           "target_type":"license",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "visibility_dependency_field_id":"properties_maintenance_currency",
           "group":"Maintenance"
        },
        "active":true,
        "position":43
     },
     {
        "id":"properties_procured_by",
        "data":{
           "label":"Procured by",
           "attribute":[
              "properties",
              "procured_by"
           ],
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "type":"text",
           "target_type":"license",
           "group":"Invoice Information"
        },
        "active":true,
        "position":44
     },
     {
        "id":"attachments",
        "data":{
           "label":"Attachments",
           "attribute":"attachments",
           "type":"attachment",
           "group":"General Information",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           }
        },
        "active":true,
        "position":45
     },
     {
        "id":"properties_umzug",
        "data":{
           "label":"Umzug",
           "attribute":[
              "properties",
              "umzug"
           ],
           "type":"select",
           "target_type":"item",
           "values":[
              {
                 "label":"zügeln",
                 "value":"zügeln"
              },
              {
                 "label":"sofort entsorgen",
                 "value":"sofort entsorgen"
              },
              {
                 "label":"bei Umzug entsorgen",
                 "value":"bei Umzug entsorgen"
              },
              {
                 "label":"bei Umzug verkaufen",
                 "value":"bei Umzug verkaufen"
              }
           ],
           "default":"zügeln",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"Umzug"
        },
        "active":true,
        "position":46
     },
     {
        "id":"properties_zielraum",
        "data":{
           "label":"Zielraum",
           "attribute":[
              "properties",
              "zielraum"
           ],
           "type":"text",
           "target_type":"item",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"Umzug"
        },
        "active":true,
        "position":47
     },
     {
        "id":"properties_ankunftsdatum",
        "data":{
           "label":"Ankunftsdatum",
           "attribute":[
              "properties",
              "ankunftsdatum"
           ],
           "type":"date",
           "target_type":"item",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"Toni Ankunftskontrolle"
        },
        "active":true,
        "position":48
     },
     {
        "id":"properties_ankunftszustand",
        "data":{
           "label":"Ankunftszustand",
           "attribute":[
              "properties",
              "ankunftszustand"
           ],
           "type":"select",
           "target_type":"item",
           "values":[
              {
                 "label":"intakt",
                 "value":"intakt"
              },
              {
                 "label":"transportschaden",
                 "value":"transportschaden"
              }
           ],
           "default":"intakt",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"Toni Ankunftskontrolle"
        },
        "active":true,
        "position":49
     },
     {
        "id":"properties_ankunftsnotiz",
        "data":{
           "label":"Ankunftsnotiz",
           "attribute":[
              "properties",
              "ankunftsnotiz"
           ],
           "type":"textarea",
           "target_type":"item",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"Toni Ankunftskontrolle"
        },
        "active":true,
        "position":50
     },
     {
        "id":"properties_anschaffungskategorie",
        "data":{
           "label":"Beschaffungsgruppe",
           "attribute":[
              "properties",
              "anschaffungskategorie"
           ],
           "value_label":[
              "properties",
              "anschaffungskategorie"
           ],
           "required":true,
           "type":"select",
           "target_type":"item",
           "values":[
              {
                 "label":"",
                 "value":nil
              },
              {
                 "label":"Werkstatt-Technik",
                 "value":"Werkstatt-Technik"
              },
              {
                 "label":"Produktionstechnik",
                 "value":"Produktionstechnik"
              },
              {
                 "label":"AV-Technik",
                 "value":"AV-Technik"
              },
              {
                 "label":"Musikinstrumente",
                 "value":"Musikinstrumente"
              },
              {
                 "label":"Facility Management",
                 "value":"Facility Management"
              },
              {
                 "label":"IC-Technik/Software",
                 "value":"IC-Technik/Software"
              },
              {
                 "label":"Durch Kunde beschafft",
                 "value":"Durch Kunde beschafft"
              }
           ],
           "default":nil,
           "visibility_dependency_field_id":"is_inventory_relevant",
           "visibility_dependency_value":"true",
           "permissions":{
              "role":"inventory_manager",
              "owner":true
           },
           "group":"Inventory"
        },
        "active":true,
        "position":51
     }
  ]
end
