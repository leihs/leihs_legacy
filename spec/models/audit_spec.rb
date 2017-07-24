require 'rails_helper'

describe Audit do
  it 'each audited class should have :label_for_audits method' do
    described_class.audited_classes.each do |klass|
      expect(klass.instance_methods).to include :label_for_audits
    end
  end
end
