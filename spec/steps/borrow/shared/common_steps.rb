module Borrow
  module Spec
    module CommonSteps
      step 'I pry' do
        # rubocop:disable Lint/Debugger
        binding.pry
        # rubocop:enable Lint/Debugger
      end
    end
  end
end
