require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

module LeihsAdmin
  module Spec
    module SuppliersSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps

      step 'I see a list of suppliers' do
        within '.list-of-lines' do
          Supplier.limit(5).each do |supplier|
            find('.row > .col-sm-6', match: :prefer_exact, text: supplier.name)
          end
        end
      end

      step 'I create a new supplier :whether_providing ' \
           'all required values' do |whether_providing|
        find('.btn', text: _('Create %s') % _('Supplier')).click
        unless whether_providing
          # not providing supplier[name]        9
        else
          @name = Faker::Address.street_address
          find("input[name='supplier[name]']").set @name
        end
      end

      step 'I see the :new_or_existing supplier' do |_|
        within '.list-of-lines' do
          find('.row > .col-sm-6', text: @name)
        end
      end

      step 'I see the supplier form' do
        within 'form' do
          find("input[name='supplier[name]']")
        end
      end

      step 'I edit an existing supplier' do
        within '.list-of-lines' do
          first('.row > .col-sm-2 > .btn', text: _('Edit')).click
        end

        @name = Faker::Address.street_address
        find("input[name='supplier[name]']").set @name
      end

      step 'there is a deletable supplier' do
        @supplier = Supplier.all.detect(&:can_destroy?)
        @supplier ||= FactoryGirl.create(:supplier)
        expect(@supplier).not_to be_nil
        expect(@supplier.can_destroy?).to be true
      end

      step 'I delete a supplier' do
        ############################################################
        # NOTE: removing header and footer
        # they are causing problems on Cider => covering the element
        # we want to click on
        page.execute_script %($('header').remove();)
        page.execute_script %($('footer').remove();)
        ############################################################

        within '.list-of-lines' do
          el = find('.row', text: @supplier.name)

          within el do
            find('.dropdown-toggle').click
            find('.dropdown-menu a', text: _('Delete')).click
            step 'I confirm the dialog'
          end
        end
      end

      step "I don't see the deleted supplier" do
        within '.list-of-lines' do
          expect(has_no_selector?('.row > .col-sm-6', text: @supplier.name))
            .to be true
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::SuppliersSteps, leihs_admin_suppliers: true
end
