require 'rails_helper'
require "#{Rails.root}/features/support/dataset"

module Spec
  module PersonasDumpSteps
    step 'personas dump is loaded' do
      ::Dataset.restore_dump
    end
  end
end
