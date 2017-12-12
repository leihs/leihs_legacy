placeholder :boolish do
  match(/(has the)/) { true }
  match(/(has no)/) { false }
end

placeholder :optional_text do
  match(/.*/) { |str| str }
  match(//) { nil }
end

module LeihsAdmin
  module Spec
    module CommonSteps
      step 'I save' do
        click_on _('Save')
      end

      step 'I see an error message' do
        find('#flash .error')
      end

      step 'I see a success message' do
        find('#flash .success')
      end

      step 'I see a notification message' do
        find('#flash .notice')
      end

      step 'I confirm the dialog' do
        alert = page.driver.browser.switch_to.alert
        alert.accept
      end

      step 'I click on :label' do |label|
        click_on _(label)
      end

      step 'I pry' do
        # rubocop:disable Lint/Debugger
        binding.pry
        # rubocop:enable Lint/Debugger
      end

      step 'I click on :label inside the dropdown menu' do |label|
        within '.dropdown-menu' do
          click_on _(label)
        end
      end

      step 'I see :label option in the dropdown menu' do |label|
        within '.dropdown-menu' do
          expect(page).to have_content _(label)
        end
      end

      def scroll_to_top
        page.execute_script 'window.scrollBy(0,-10000)'
      end

      def scroll_down(x)
        page.execute_script "window.scrollBy(0,#{x})"
      end

      def scroll_up(x)
        page.execute_script "window.scrollBy(0,-#{x})"
      end

      def remove_nav
        page.execute_script "$('nav').remove()"
      end

      def remove_footer
        page.execute_script "$('footer').remove()"
      end
    end
  end
end
