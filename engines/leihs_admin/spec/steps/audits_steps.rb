require_relative 'shared/common_steps'
require_relative '../../../../spec/steps/shared/login_steps'
require_relative 'shared/navigation_steps'
require_relative 'shared/personas_dump_steps'

placeholder :count do
  match /\d+/, &:to_i
end

# rubocop:disable Metrics/ModuleLength
module LeihsAdmin
  module Spec
    module AuditsSteps
      include ::LeihsAdmin::Spec::CommonSteps
      include ::LeihsAdmin::Spec::NavigationSteps
      include ::LeihsAdmin::Spec::PersonasDumpSteps
      include ::Spec::LoginSteps

      step 'I click on the :tab navigation tab' do |tab|
        within '.container .nav-tabs' do
          click_on _(tab)
        end
      end

      step 'I see the list of audits' do
        within '.pages' do
          expect(page).to have_selector '.panel'
        end
      end

      step 'there is a user whose name contains :term' do |term|
        @user = FactoryGirl.create(:user, lastname: term)
      end

      step 'there is an item whose inventory code contains :term' do |term|
        @item = FactoryGirl.create(:item,
                                   inventory_code: term,
                                   shelf: Faker::Lorem.word)
      end

      step "there is a 'create' audit which contains :term " \
           "in column 'audited_changes'" do |term|
        FactoryGirl.create(:item, shelf: term)
      end

      step "there is a 'create' audit for a user " \
           'whose name contains :term' do |term|
        expect(Audit.find_by(action: 'create', auditable_id: @user.id)).to be
      end

      step "there is a 'create' audit performed by a user " \
           'whose name contains :term' do |term|
        item = FactoryGirl.create(:item)
        item.audits.first.update_attributes(user: @user)
      end

      step "there is a 'create' audit for an item " \
           'whose inventory code contains :term' do |term|
        expect(Audit.find_by(action: 'create', auditable_id: @item.id)).to be
      end

      step "there is an 'update' audit for an item whose " \
           'inventory code contains :term' do |term|
        @item.update_attributes(shelf: Faker::Lorem.word)
      end

      step "there is a 'create' audit for a model " \
           'whose name contains :term' do |term|
        FactoryGirl.create(:model, product: term)
      end

      step 'I navigate to the audits page' do
        visit admin.audits_path
      end

      step 'I enter :term in the search input field' do |term|
        fill_in 'search_term', with: term
      end

      step 'click on :label' do |label|
        click_on _(label)
      end

      step 'I scroll down until I see all audits' do
        # rubocop:disable Lint/Loop
        begin
          counter = all('.panel').count
          scroll_down 10000
        end until all('.panel').count == counter
        # rubocop:enable Lint/Loop
      end

      step 'I see :count audits' do |count|
        within '.pages' do
          expect(all('.panel').count).to be == count
        end
      end

      step 'the end date is set to today' do
        expect(find("input[name='end_date']").value).to be == I18n.l(Date.today)
      end

      step 'the start date is set to one month ago' do
        expect(find("input[name='start_date']").value)
          .to be == I18n.l(30.days.ago.to_date)
      end

      step 'I see the request with the new audit at the top' do
        request_el = first('.panel')
        expect(request_el['data-request_id']).to be == @audit.request_uuid
        within request_el do
          expect(page).to have_selector ".row[data-id='#{@audit.id}']"
        end
      end

      step 'there exists a new audit' do
        item = FactoryGirl.create(:item)
        @audit = Audit.find_by_auditable_id(item.id)
      end

      step 'there exists a new audit for an item' do
        @item = FactoryGirl.create(:item)
        @audit = Audit.find_by_auditable_id(@item.id)
      end

      step 'I see the inventory code of the item on its audit entry' do
        expect(find(".row[data-id='#{@audit.id}']"))
          .to have_content @item.inventory_code
      end

      step 'there exists a new audit for a model' do
        @model = FactoryGirl.create(:model)
        @audit = Audit.find_by_auditable_id(@model.id)
      end

      step 'I see the model name of the model on its audit entry' do
        expect(find(".row[data-id='#{@audit.id}']"))
          .to have_content @model.name
      end

      step 'there exists a new audit for a user' do
        @user = FactoryGirl.create(:user)
        @audit = Audit.find_by_auditable_id(@user.id)
      end

      step 'I see the user name of the user on its audit entry' do
        expect(find(".row[data-id='#{@audit.id}']"))
          .to have_content @user.name
      end

      step 'there is a label method defined for every audited entity' do
        Audit.audited_classes.each do |klass|
          expect(klass.instance_methods).to include :label_for_audits
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength

RSpec.configure do |config|
  config.include LeihsAdmin::Spec::AuditsSteps, leihs_admin_audits: true
end
