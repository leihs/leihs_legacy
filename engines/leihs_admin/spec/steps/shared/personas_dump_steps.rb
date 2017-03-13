require 'rails_helper'
require "#{Rails.root}/features/support/dataset"

module LeihsAdmin
  module Spec
    module PersonasDumpSteps
      step 'personas dump is loaded' do
        ::Dataset.restore_random_dump('normal')
      end
    end
  end
end
