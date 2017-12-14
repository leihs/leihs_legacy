require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

placeholder :whether_providing do
  match('not providing') do
    false
  end
  match('providing') do
    true
  end
end

module LeihsAdmin
  module Spec
    module BuildingSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps

      step 'I see a list of buildings' do
        find('.nav-tabs .active', text: _('Buildings'))
        within '.list-of-lines' do
          Building.limit(5).each do |building|
            find('.row > .col-sm-3', text: building.name)
          end
        end
      end

      step 'I see a list of all buildings' do
        find('.nav-tabs .active', text: _('Buildings'))
        within '.list-of-lines' do
          Building.all.each do |building|
            find(".row[data-id='#{building.id}']")
          end
        end
      end

      step 'the first row contains name of the building' do
        @first_row = first('.list-of-lines .row')
        @first_building = Building.find(@first_row['data-id'])
        expect(@first_row).to have_content @first_building.name
      end

      step 'the first row contains code of the building' do
        @first_row ||= first('.list-of-lines .row')
        @first_building ||= Building.find(@first_row['data-id'])
        expect(@first_row).to have_content @first_building.code
      end

      step 'the first row contains rooms count of the building' do
        @first_row ||= first('.list-of-lines .row')
        @first_building ||= Building.find(@first_row['data-id'])
        expect(@first_row)
          .to have_content "#{@first_building.rooms.count} #{_('rooms')}"
      end

      step 'the first row contains items count of the building' do
        @first_row ||= first('.list-of-lines .row')
        @first_building ||= Building.find(@first_row['data-id'])
        expect(@first_row)
          .to have_content "#{@first_building.items.count} #{_('items')}"
      end

      step 'the general building row contains the general label' do
        @general_building ||= Building.general
        @general_row ||= \
          find(".list-of-lines .row[data-id='#{@general_building.id}']")
        expect(@general_row).to have_content _('general')
      end

      step 'the general building row is highlighted' do
        @general_building ||= Building.general
        @general_row ||= \
          find(".list-of-lines .row[data-id='#{@general_building.id}']")
        expect(@general_row.native.attribute(:class)).to include 'text-warning'
      end

      step 'the buildings are sorted alphabetically' do
        ids = all('.list-of-lines .row').map { |r| r['data-id'] }
        expect(Building.order('lower(name) ASC').map(&:id)).to be == ids
      end

      step 'I create a new building :whether_providing ' \
           'all required values' do |whether_providing|
        find('.btn', text: _('Create %s') % _('Building')).click
        unless whether_providing
          # not providing building[name]
        else
          @name = Faker::Address.street_address
          @code = Faker::Address.building_number
          find("input[name='building[name]']").set @name
          find("input[name='building[code]']").set @code
        end
      end

      step 'I see the :adjective building' do |arg1 = nil|
        within '.list-of-lines' do
          find('.row > .col-sm-3', text: @name)
        end
      end

      step 'I see the building form' do
        within 'form' do
          find("input[name='building[name]']")
        end
      end

      step 'I edit an existing building' do
        within '.list-of-lines' do
          first('.row > .col-sm-2 > .btn', text: _('Edit')).click
        end

        @name = Faker::Address.street_address
        @code = Faker::Address.building_number
        find("input[name='building[name]']").set @name
        find("input[name='building[code]']").set @code
      end

      step 'there is a deletable building' do
        @building = Building.all.detect(&:can_destroy?)
        @building ||= FactoryGirl.create(:building,
                                         name: Faker::Address.street_address,
                                         code: Faker::Address.building_number)
        expect(@building).not_to be_nil
        expect(@building.can_destroy?).to be true
      end

      step 'I delete a building' do
        within '.list-of-lines' do
          within('.row', text: @building.name) do
            find('.dropdown-toggle').click
            find('.dropdown-menu a', text: _('Delete')).click
            step 'I confirm the dialog'
          end
        end
      end

      step "I don't see the deleted building" do
        within '.list-of-lines' do
          expect(
            has_no_selector?('.row > .col-sm-4', text: @building.name)
          ).to be true
        end
      end

      step 'a general room for this building was created in the database' do
        expect(Room.where(general: true).find_by_building_id(@building.id)).to be
      end

      step 'the new building was created in the database' do
        @building = Building.find_by_name(@name)
        expect(Room.where(general: true).find_by_building_id(@building.id)).to be
      end

      step 'the building was deleted from the database' do
        expect(Building.find_by_id(@building.id)).not_to be
      end

      step 'its general room was deleted from the database too' do
        expect(Room.find_by(building_id: @building.id, general: true))
          .not_to be
      end
    end
  end
end

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::BuildingSteps, leihs_admin_buildings: true
end
