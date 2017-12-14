require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative '../../../../spec/steps/shared/factory_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module RoomsSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::FactorySteps
      include ::Spec::LoginSteps

      step 'there exists a room :room for building :building' \
        do |room_name, building_name|
        building = Building.find_by_name(building_name)
        building ||= FactoryGirl.create(:building, name: building_name)
        @room = FactoryGirl.create(:room, name: room_name, building: building)
      end

      step 'this room has 1 item' do
        FactoryGirl.create(:item, room: @room)
      end

      step 'I visit the list of rooms' do
        visit admin.rooms_path
      end

      step 'I see the list of rooms sorted in the following manner:' do |table|
        table.hashes.each_with_index do |h, i|
          expect(all('.list-of-lines .row .col-sm-3:nth-child(1)')[i].text)
            .to be == h['room_name']
          expect(all('.list-of-lines .row .col-sm-3:nth-child(2)')[i].text)
            .to be == h['building_name']
        end
      end

      step 'each room line displays the number of items placed in it' do
        all('.list-of-lines .row').each do |row|
          room_name = row.find('div:nth-child(1)', match: :first).text
          building_name = row.find('div:nth-child(2)', match: :first).text
          building = Building.find_by_name(building_name)
          room = Room.find_by(name: room_name, building_id: building.id)
          expect(row.find('div:nth-child(4)', match: :first).text)
            .to match /^#{room.items.count}/
        end
      end

      step 'each general room line displays the general label in it' do
        all('.list-of-lines .row').each do |row|
          room = Room.find(row['data-id'])
          next unless room.general
          expect(row).to have_content _('general')
        end
      end

      step 'each general room line is highlighted' do
        all('.list-of-lines .row').each do |row|
          room = Room.find(row['data-id'])
          next unless room.general
          expect(row.native.attribute(:class)).to include ('text-warning')
        end
      end

      step 'the edit button' do
        all('.list-of-lines .row').each do |row|
          row.find('[href]', text: _('Edit'))
        end
      end

      step 'I click on the edit button for the row of the room' do
        button = \
          find(".list-of-lines .row [href='#{admin.edit_room_path(@room)}']")
        button.click
      end

      step 'I see the edit room page' do
        expect(current_path).to be == admin.edit_room_path(@room)
      end

      step 'I see the create room page' do
        expect(current_path).to be == admin.new_room_path
      end

      step 'I enter the name' do
        @new_name = Faker::Lorem.word
        fill_in 'room[name]', with: @new_name
      end

      step 'I enter the name :name' do |name|
        fill_in 'room[name]', with: name
      end

      step 'I enter the description' do
        @new_description = Faker::Lorem.words(3).join(' ')
        fill_in 'room[description]', with: @new_description
      end

      step 'I choose the building from the select box' do
        select @building.name, from: 'room[building_id]'
      end

      step 'I choose the building :building from the select box' do |building|
        select building, from: 'room[building_id]'
      end

      step 'a second room with name :room and ' \
           'building :building was not created' do |room, building|
        expect(
          Room.includes(:building)
          .where(name: room, buildings: { name: building })
          .count
        ).to be == 1
      end

      step 'the room with name :room and ' \
           'building :building was not created' do |room, building|
        expect(
          Room.includes(:building)
          .find_by(name: room, buildings: { name: building })
        ).not_to be
      end

      step 'I am redirected to the list of rooms' do
        expect(current_path).to be == admin.rooms_path
      end

      step 'the room was saved successfully' do
        Room.find_by(name: @new_name,
                     description: @new_description,
                     building: @building)
      end

      step 'I click on create room button' do
        label = _('Create %s') % _('Room')
        find('a', text: label).click
      end

      step 'the room was created successfully' do
        step 'the room was saved successfully'
      end

      step "I don't see the delete button on the row for the room" do
        row = \
          find('.list-of-lines .row', text: "#{@room.name} #{@room.building.name}")
        expect(row).not_to have_content _('Delete')
      end

      step 'I click on the delete button for the room' do
        row = \
          find('.list-of-lines .row', text: "#{@room.name} #{@room.building.name}")
        row.find("[data-toggle='dropdown']").click
        row.find("a[data-method='delete']").click
      end

      step 'the room was deleted successfully' do
        expect(Room.find_by_id(@room.id)).not_to be
      end

      step 'I click on the edit button for the row of the general room' do
        @room ||= Room.general.first
        within(".list-of-lines .row[data-id='#{@room.id}']") do
          click_on _('Edit')
        end
      end

      step 'I search for the name of a general room' do
        @room ||= Room.general.first
        fill_in 'search_term', with: @room.name
        click_on _('Search')
      end

      step 'I search for the name of the general room' do
        step 'I search for the name of a general room'
      end

      step 'I visit the edit page of a general room' do
        @room ||= Room.general.first
        visit admin.edit_room_path(@room)
      end

      step 'I cannot choose the building from the select box' do
        expect(find("select[name='room[building_id]']")).to be_disabled
      end

      step 'there are no items for the general room' do
        room = FactoryGirl.create(:room)
        Item.where(room_id: @room.id).each do |item|
          item.update_column(:room_id, room.id)
        end
      end

      step 'there are no procurement requests for the general room' do
        room = FactoryGirl.create(:room)
        Procurement::Request.where(room_id: @room.id).each do |request|
          request.update_column(:room_id, room.id)
        end
      end

      step 'I scrool down until I see the line for the general room' do
        scroll_down 10000 until first(".row[data-id='#{@room.id}']")
      end

      step 'there is a general room' do
        @room = Room.general.first
      end
    end
  end
end

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::RoomsSteps, leihs_admin_rooms: true
end
