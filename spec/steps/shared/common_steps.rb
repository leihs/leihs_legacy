module Spec
  module CommonSteps
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

    step 'I close the flash message if visible' do
      flash = first("#flash")
      if flash
        flash.find(".fa-times-circle").click
      end
    end

    step 'I release the focus from this field' do
      find('body').click # blur all possible focused autocomplete inputs
    end
  end
end
