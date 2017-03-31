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
  end
end
