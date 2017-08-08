module Spec
  module CommonSteps
    step 'I pry' do
      # rubocop:disable Lint/Debugger
      binding.pry
      # rubocop:enable Lint/Debugger
    end

    def wait_until(wait_time = 60, &block)
      begin
        Timeout.timeout(wait_time) do
          until value = block.call
            sleep(1)
          end
          value
        end
      rescue Timeout::Error
        # rubocop:disable Style/RaiseArgs
        fail Timeout::Error.new(block.source)
        # rubocop:enable Style/RaiseArgs
      end
    end

    def hover_for_tooltip(target)
      page.driver.browser.action.move_to(target.native).perform
      find('.tooltipster-content') # there should be just one
    end

    def type_into_autocomplete(selector, value)
      raise 'please provide a value' if value.size.zero?
      step 'I release the focus from this field'
      find(selector).click
      find(selector).set value
      find('.ui-autocomplete')
    end

    def type_into_and_select_from_autocomplete(selector, value)
      type_into_autocomplete(selector, value)
      within '.ui-autocomplete' do
        find('.ui-menu-item', text: value).click
      end
    end

    step 'I close the flash message if visible' do
      flash = first('#flash')
      if flash
        flash.find('.fa-times-circle').click
      end
    end

    step 'I release the focus from this field' do
      find('body').click # blur all possible focused autocomplete inputs
    end

    step 'I save' do
      find('#save').click
    end

    step 'I accept the confirmation dialog' do
      page.driver.browser.switch_to.alert.accept
    end

    step 'I cancel the confirmation dialog' do
      page.driver.browser.switch_to.alert.dismiss
    end

    step 'I see a success message' do
      find('#flash .success')
    end

    def rescue_displaced_flash
      begin
        yield
      rescue
        find('#flash .fa-times-circle').click
        retry
      end
    end
  end
end
