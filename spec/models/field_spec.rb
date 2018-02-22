require 'rails_helper'
require "#{Rails.root}/features/support/dataset"

describe Field do
  before :all do
    ::Dataset.restore_dump
  end

  it 'raises on INSERT' do
    expect { Field.create! }
      .to raise_error \
        /New fields must always be dynamic./
  end
  it 'raises on DELETE' do
    expect { Field.first.destroy! }
      .to raise_error \
        /Cannot delete field which is not dynamic./
  end
end
