require_relative '../shared/common_steps'
require_relative '../shared/login_steps'
require_relative '../shared/personas_dump_steps'

module Borrow
  module Spec
    module ModelListSteps
      include ::Spec::CommonSteps
      include ::Spec::LoginSteps
      include ::Spec::PersonasDumpSteps

      step 'I am listing some available models' do
        @category = Category.find do |c|
          c.models.any? do |m|
            m.availability_in(@current_user.inventory_pools.first)
              .maximum_available_in_period_summed_for_groups(
                Date.today, Date.today, @current_user.group_ids) >= 1
          end
        end
        visit borrow_models_path(category_id: @category.id)
      end

      step 'I am listing models' do
        @category = Category.first
        visit borrow_models_path(category_id: @category.id)
      end

      step 'I am listing models and some of them are unavailable' do
        @start_date ||= Date.today
        @end_date ||= Date.today + 1.day
        model = @current_user.models.borrowable.detect do |m|
          quantity = @current_user.inventory_pools.to_a.sum do |ip|
            m.availability_in(ip).maximum_available_in_period_summed_for_groups(
              @start_date,
              @end_date,
              @current_user.groups.map(&:id)
            )
          end
          quantity <= 0 and not m.categories.blank?
        end
        @category = model.categories.first

        visit borrow_models_path(category_id: @category.id)

        within '#model-list-search' do
          find('input').click
          find('input').set model.name
        end
      end

      step 'the model list shows models from all inventory pools' do
        within '#model-list' do
          expect(
            @current_user
            .models
            .borrowable
            .from_category_and_all_its_descendants(@category)
            .default_order.paginate(page: 1, per_page: 20)
            .map(&:name)
          ).to eq all('.text-align-left').map(&:text).select { |t| not t.blank? }
        end
      end

      step 'the filter is labeled :button_label' do |button_label|
        within '#ip-selector' do
          find('.button', text: button_label)
        end
      end

      step 'I select a specific inventory pool from the choices offered' do
        find('#ip-selector').click
        expect(
          has_selector?('#ip-selector .dropdown .dropdown-item', visible: true)
        ).to be true
        @current_inventory_pool ||= @current_user.inventory_pools.first
        find('#ip-selector .dropdown .dropdown-item',
             text: @current_inventory_pool.name).click
      end

      step 'all other inventory pools are deselected' do
        find('#ip-selector').click unless first('#ip-selector .dropdown')
        (@current_user.inventory_pools - [@current_inventory_pool]).each do |ip|
          expect(find('#ip-selector .dropdown-item', text: ip.name, visible: false)
            .find('input', match: :first).checked?).to be false
        end
      end

      step 'the model list shows only models of this inventory pool' do
        within '#model-list' do
          expect(all('.text-align-left').map(&:text).reject(&:empty?))
            .to eq \
              @current_user.models.borrowable
              .from_category_and_all_its_descendants(@category)
              .by_inventory_pool(@current_inventory_pool.id)
              .default_order.paginate(page: 1, per_page: 20)
              .map(&:name)
        end
      end

      step 'the inventory pool selector is no longer expanded' do
        expect(find('#ip-selector .dropdown').visible?).to be false
      end

      step 'the filter shows the name of the selected inventory pool' do
        expect(
          has_selector?('#ip-selector .button',
                        text: @current_inventory_pool.name)
        ).to be true
      end

      step 'I deselect some inventory pools' do
        find('#ip-selector').click
        @current_inventory_pool = @current_user.inventory_pools.first
        @dropdown_element = find('#ip-selector .dropdown')
        @dropdown_element
          .find('.dropdown-item',
                match: :first,
                text: @current_inventory_pool.name)
          .find('input', match: :first).click
      end

      step 'the model list is filtered by the left over inventory pools' do
        within '#model-list' do
          expect(has_selector?('.text-align-left')).to be true
          expect(all('.text-align-left').map(&:text)).to eq \
            @current_user.models.borrowable
            .from_category_and_all_its_descendants(@category)
            .all_from_inventory_pools(
              @current_user.inventory_pool_ids - [@current_inventory_pool.id]
            )
            .default_order
            .paginate(page: 1, per_page: 20)
            .map(&:name)
        end
      end

      step 'the model list is filtered by the left over inventory pool' do
        within '#model-list' do
          expect(has_selector?('.text-align-left')).to be true
          expect(
            all('.text-align-left').map(&:text).reject(&:empty?)[0..20]
          ).to eq \
            @current_user.models.borrowable
            .from_category_and_all_its_descendants(@category)
            .all_from_inventory_pools(
              @current_user.inventory_pool_ids - @ips_for_unselect.map(&:id)
            )
            .default_order
            .paginate(page: 1, per_page: 20)
            .map(&:name)
        end
      end

      step 'the inventory pool selector is still expanded' do
        expect(find('#ip-selector .dropdown').visible?).to be true
      end

      step 'I deselect all but one inventory pool' do
        find('#ip-selector').click
        @current_inventory_pool = @current_user.inventory_pools.first
        @ips_for_unselect = \
          @current_user
          .inventory_pools
          .where('inventory_pools.id != ?', @current_inventory_pool.id)
        @ips_for_unselect.each do |ip|
          find('#ip-selector .dropdown-item', text: ip.name)
            .find('input', match: :first)
            .click
        end
      end

      step 'the filter shows the name of the inventory pool that is left' do
        find('#ip-selector .button', text: @current_inventory_pool.name)
      end

      step 'I cannot deselect all the inventory pools ' \
           'in the inventory pool selector' do
        find('#ip-selector').click
        within '#ip-selector' do
          inventory_pool_ids = \
            all('.dropdown-item[data-id]').map { |item| item['data-id'] }
          inventory_pool_ids.each do |ip_id|
            expect(has_selector?('.dropdown .dropdown-item', visible: true))
              .to be true
            find(".dropdown-item[data-id='#{ip_id}']").click
          end
          expect(has_selector?('.dropdown-item input:checked')).to be true
        end
      end

      step 'the inventory pool selection is ordered alphabetically' do
        find('#ip-selector').click unless first('#ip-selector .dropdown')
        wait_until { first('#ip-selector .dropdown') }
        within '#ip-selector' do
          expect(all('.dropdown-item[data-id]').map(&:text)).to eq \
            @current_user.inventory_pools.order('inventory_pools.name').map(&:name)
        end
      end

      step 'the filter shows the count of selected inventory pools' do
        number_of_selected_ips = \
          (@current_user.inventory_pool_ids - [@current_inventory_pool.id]).length
        find('#ip-selector .button',
             text: (number_of_selected_ips.to_s + ' ' + _('Inventory pools')))
      end

      step 'I sort the list by :sort_order' do |sort_order|
        find('#model-sorting').click unless first('#model-sorting .dropdown')
        text = case sort_order
               when 'Model, ascending'
                 "#{_('Model')} (#{_('ascending')})"
               when 'Model, descending'
                 "#{_('Model')} (#{_('descending')})"
               when 'Manufacturer, ascending'
                 "#{_('Manufacturer')} (#{_('ascending')})"
               when 'Manufacturer, descending'
                 "#{_('Manufacturer')} (#{_('descending')})"
               end
        find('#model-sorting a', text: text).click
        find('#model-list .line', match: :first)
      end

      step 'the list is sorted by :sort, :order' do |sort, order|
        attribute = case sort
                    when 'Model'
                      'name'
                    when 'Manufacturer'
                      'manufacturer'
                    end
        direction = case order
                    when 'ascending'
                      'asc'
                    when 'descending'
                      'desc'
                    end
        within '#model-list' do
          expect(all('.text-align-left').map(&:text).reject(&:empty?)).to eq \
            @current_user.models.borrowable
            .from_category_and_all_its_descendants(@category)
            .order_by_attribute_and_direction(attribute, direction)
            .paginate(page: 1, per_page: 20)
            .map(&:name)
        end
      end

      step 'those models are shown whose names or ' \
           'manufacturers match the search term' do
        expect(
          all('#model-list .line', text: /.*#{@search_term}.*/i).first.text
        ).to match(/.*#{@search_term}.*/)
      end

      step 'no lending period is set' do
        expect(find('#start-date').value).to be_blank
        expect(find('#end-date').value).to be_blank
      end

      step 'I choose a start date' do
        @start_date ||= Date.today
        find('#start-date').set I18n.l @start_date
        find('.ui-state-active').click
      end

      step 'I choose a end date' do
        @end_date ||= @start_date + 1
        find('#end-date').set I18n.l @end_date
        find('#end-date').click
        find('.ui-state-active').click
      end

      step 'I select a sorting option' do
        find('#model-sorting').click unless first('#model-sorting .dropdown')
        within '#model-sorting' do
          el = find('.dropdown-item', match: :first)
          @sorting = el.text
          el.click
        end
      end

      step 'the end date is automatically set to the next day' do
        @end_date ||= Date.today + 1.day
        expect(find('#end-date').value).to eq I18n.l(@end_date)
      end

      step 'the list is filtered by models that are ' \
           'available in that time frame' do
        within '#model-list' do
          all('.line[data-id]', minimum: 1).each do |model_el|
            model = \
              Model.find_by_id(model_el['data-id']) \
              || Model.find_by_id(model_el.reload['data-id'])
            expect(model).not_to be_nil
            quantity = @current_user.inventory_pools.to_a.sum do |ip|
              model
                .availability_in(ip)
                .maximum_available_in_period_summed_for_groups(
                  @start_date,
                  @end_date,
                  @current_user.groups.map(&:id)
                )
            end
            if quantity <= 0
              @unavailable_model_found = true
              expect(model_el[:class]['grayed-out']).to be
            else
              expect(model_el[:class]['grayed-out']).not_to be
            end
          end
          expect(@unavailable_model_found).not_to be_nil
        end
      end

      step 'I choose an end date' do
        @end_date = Date.today + 1.day
        fill_in 'end-date', with: (I18n.l @end_date)
      end

      step 'the start date is automatically set to the previous day' do
        # NOTE this sleep is required because waiting for onchange event
        sleep(0.55)
        @start_date = @end_date - 1.day
        expect(find('#start-date').value).to eq I18n.l(@start_date)
      end

      step 'I blank the start and end date' do
        fill_in 'start-date', with: ''
        fill_in 'end-date', with: ''
      end

      step 'the list is not filtered by lending time frame' do
        expect(has_no_selector?('.grayed-out')).to be true
      end

      step 'I can also use a date picker to specify start and ' \
           'end date instead of entering them by hand' do
        find('#start-date').set I18n.l Date.today
        find('.ui-datepicker')
        find('#end-date').set I18n.l Date.today
        find('.ui-datepicker')
      end

      step 'I see the models of the selected category' do
        @category = \
          Category.find \
            Rack::Utils.parse_nested_query(
              URI.parse(current_url).query
            )['category_id']
        models = \
          @current_user
          .models
          .borrowable
          .from_category_and_all_its_descendants(@category)
        within '#model-list' do
          find('.line[data-id]', match: :first)
          all('.line[data-id]').reject { |el| el.text.blank? }.each do |model_line|
            model = Model.find model_line['data-id']
            expect(models.include? model).to be true
          end
        end
      end

      step 'I see the sort options' do
        within '#model-sorting' do
          expect(has_selector?('.dropdown *[data-sort]', visible: false))
            .to be true
        end
      end

      step 'I see the inventory pool selector' do
        within '#ip-selector' do
          expect(has_selector?('.dropdown', visible: false)).to be true
        end
      end

      step 'I see filters for start and end date' do
        expect(has_selector?('#start-date')).to be true
        expect(has_selector?('#end-date')).to be true
      end

      step 'a single model list entry contains:' do |table|
        within '#model-list' do
          model_line = find('.line', match: :first)
          model = Model.find model_line['data-id']
          table.raw.map(&:first).each do |row|
            case row
            when 'Image'
              model_line.find("img[src*='#{model.id}']", match: :first)
            when 'Model name'
              model_line.find('.line-col', match: :first, text: model.name)
            when 'Manufacturer'
              model_line.find('.line-col', match: :first, text: model.manufacturer)
            when 'Selection button'
              model_line.find('.line-col .button', match: :first)
            else
              raise 'Unknown'
            end
          end
        end
      end

      step 'I see a model list that can be scrolled' do
        @category = Category.all.find { |c| c.models.length > 20 }
        visit borrow_models_path(category_id: @category.id)
      end

      step 'I scroll to the end of the currently loaded list' do
        page.execute_script "$($('.page')[1]).trigger('inview')"
      end

      step 'the next block of models is loaded and shown' do
        within '#model-list' do
          expect(all('.line').count).to be > 20
        end
      end

      step 'I scroll to the end of the list' do
        page.execute_script 'window.scrollBy(0,10000)'
      end

      step 'I scroll loading all pages' do
        all('.page[data-page]').each do |data_page|
          data_page.click
          data_page.find('.line div', match: :first)
        end
      end

      step 'all models of the chosen category have been loaded and shown' do
        within '#model-list' do
          expect(all('.line', minimum: 1).size)
            .to eq \
              @current_user
              .models
              .borrowable
              .from_category_and_all_its_descendants(@category)
              .length
        end
      end

      step 'I hover over that model' do
        find(".line[data-id='#{@model.id}']").hover
      end

      step "I see the model's name, images, description, list of properties" do
        within('.tooltipster-default') do
          find('.headline-s', text: @model.name)
          find('.paragraph-s', text: @model.description)
          @model.properties.take(5).each do |property|
            within('.row.margin-top-xs', text: property.key) do
              find('.col1of3', text: property.key)
              find('.col2of3', text: property.value)
            end
          end
          (0..@model.images.count - 1).each do |i|
            expect(
              has_selector?(
                "img[src*='/models/#{@model.id}/image_thumb?offset=#{i}']",
                visible: false
              )
            ).to be true
          end
        end
      end

      step 'there is a model with images, description and properties' do
        @model = \
          @current_user
          .models
          .borrowable
          .find do |m|
            !m.images.blank? and !m.description.blank? and !m.properties.blank?
          end
      end

      step 'the model list contains that model' do
        visit borrow_models_path(category_id: @model.categories.first)
      end

      step 'I select all inventory pools using the ' \
           '"All inventory pools" function' do
        within '#ip-selector' do
          find('.dropdown-item', text: _('All inventory pools')).click
        end
      end

      step 'all inventory pools are selected' do
        within '#ip-selector' do
          all(".dropdown-item input[type='checkbox']").each do |checkbox|
            expect(['checked', true].include?(checkbox.checked?)).to be true
          end
        end
      end

      step 'the model list contains models from all inventory pools' do
        ip_ids = \
          find('#ip-selector')
          .all('.dropdown-item[data-id]')
          .map { |ip| ip['data-id'] }
        step 'I scroll to the end of the list'
        models = \
          @current_user
          .models
          .borrowable
          .from_category_and_all_its_descendants(@category)
          .all_from_inventory_pools(ip_ids)
          .order_by_attribute_and_direction 'model', 'name'
        within '#model-list' do
          expect(
            all('.text-align-left').map(&:text).reject(&:empty?).uniq
          ).to eq models.map(&:name)
        end
      end

      step 'filters are being applied' do
        find('#model-list-search input').set 'a'

        # NOTE: these steps cause problems on Cider ###############################
        # find('input#start-date').set Date.today.strftime('%d/%m/%Y')
        # find('input#end-date').set (Date.today + 1).strftime('%d/%m/%Y')
        # step 'I release the focus from this field'
        # expect(has_no_selector?('.ui-datepicker-calendar', visible: true))
        # .to be true
        # #########################################################################

        find('#ip-selector').click
        within '#ip-selector' do
          expect(has_selector?('.dropdown-item', visible: true)).to be true
          all('.dropdown-item').last.click
        end
        find('#model-sorting').click
        within '#model-sorting' do
          expect(has_selector?('a', visible: true)).to be true
          all('a').last.click
        end
      end

      step 'the button "Reset all filters" is visible' do
        expect(find('#reset-all-filter').visible?).to be true
      end

      step 'the button "Reset all filters" is not visible' do
        expect(page).not_to have_selector('#reset-all-filter')
      end

      step 'I reset all filters' do
        find('#reset-all-filter').click
        find('#model-list .line', match: :first)
      end

      step 'all inventory pools are selected again in the inventory pool filter' do
        within '#ip-selector' do
          all("input[type='checkbox']").each &:checked?
        end
      end

      step 'start and end date are both blank' do
        expect(find('input#start-date').value.empty?).to be true
        expect(find('input#end-date').value.empty?).to be true
      end

      step 'the button \"Reset all filters\" is not visible' do
        expect(has_selector?('#reset-all-filter', visible: false)).to be true
      end

      step 'the search query field is blank' do
        expect(find('#model-list-search input').value.empty?).to be true
      end

      step 'the model list is unfiltered' do
        step 'I scroll to the end of the list'
        expect(has_no_selector?('.page.fetched')).to be true
        within '#model-list' do
          expect(all('.text-align-left').map(&:text).reject(&:empty?)).to eq \
            @current_user
            .models
            .from_category_and_all_its_descendants(@category)
            .default_order
            .map(&:name)
        end
      end

      step 'I set all filters to their default values by hand' do
        find('#model-list-search input').set ''
        find('input#start-date').set ''
        find('input#end-date').set ''
        step 'I release the focus from this field'
        expect(all('.ui-datepicker-calendar', visible: true).empty?).to be true
        find('#ip-selector').click
        expect(has_selector?('#ip-selector .dropdown-item', visible: true))
          .to be true
        all('#ip-selector .dropdown-item').first.click
        find('#model-sorting').click
        within '#model-sorting' do
          expect(has_selector?('.dropdown-item', visible: true)).to be true
          first('.dropdown-item').click
        end
      end

      step 'I open the calendar for this model' do
        find(".line[data-id='#{@model.id}'] [data-create-order-line]").click
        step 'I choose a start and end date when the inventory pool is open'
        step 'I save the booking calendar'
        step 'the modal is closed'
      end

      step 'I choose a start and end date when the inventory pool is open' do
        step 'I see the booking calendar'

        while all('.start-date.selected.available:not(.closed)').empty?
          find('#booking-calendar-start-date').native.send_key :up
        end

        rand(0..40).times do
          find('#booking-calendar-end-date').native.send_key :up
          find('.end-date')
        end
        loop do
          find('#booking-calendar-end-date').native.send_key :up
          find('.end-date')
          if page.has_selector?('.end-date.closed')
            break
          end
        end

        while all('.end-date.selected.available:not(.closed)').empty?
          find('#booking-calendar-end-date').native.send_key :up
        end
      end

      step 'I see the explorative search' do
        find '#explorative-search'
      end

      step 'I enter a search term' do
        @search_term = @category.models.first.name[0..3]
        find('#model-list-search input').set @search_term
      end

      step 'I press the Enter key' do
        find("#search input[name='search_term']").native.send_keys(:return)
      end

      step 'I see the booking calendar' do
        expect(has_selector?('#booking-calendar .fc-day-content')).to be true
      end

      step 'I save the booking calendar' do
        find('#submit-booking-calendar:not(:disabled)').click
      end

      step 'the modal is closed' do
        expect(has_no_selector?('.modal')).to be true
      end

      step 'I release the focus from this field' do
        find('body').click # blur all possible focused autocomplete inputs
      end

      step 'I click on a category from explorative search' do
        el = find('#explorative-search h2', match: :first)
        @category = Category.find_by_name(el.text)
        el.click
      end

      step 'the filter has previously entered search term' do
        expect(find('#model-list-search input').value).to be == @search_term
      end
      step 'the filter has previously selected start date' do
        expect(find('#start-date').value).to be == I18n.localize(@start_date)
      end
      step 'the filter has previously selected end date' do
        expect(find('#end-date').value).to be == I18n.localize(@end_date)
      end
      step 'the filter has previously selected inventory pool' do
        expect(
          has_selector?('#ip-selector .button',
                        text: @current_inventory_pool.name)
        ).to be true
      end

      step 'the filter has previously selected sorting option' do
        expect(@sorting).to start_with find('#model-sorting').text
      end

      step 'I switch to another language' do
        @original_language = @current_user.language
        @another_language = Language.all.detect { |l| l != @current_user.language }
        I18n.locale = @another_language.locale_name
        find('footer a', text: @another_language.name).click
      end

      step 'I switch back to original language' do
        I18n.locale = @original_language.locale_name
        find('footer a', text: @original_language.name).click
      end

      step 'I visit the start page' do
        find('#start').click
      end

      step 'I click on a root category' do
        el = find('[data-category_id]', match: :first)
        @category = Category.find(el['data-category_id'])
        el.click
      end
    end
  end
end

RSpec.configure do |config|
  config.include Borrow::Spec::ModelListSteps, borrow_model_list: true
end
