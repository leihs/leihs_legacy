require 'rails_helper'
require "#{Rails.root}/features/support/dataset"

describe Field do
  before :all do
    ::Dataset.restore_dump
  end

  it 'raises on INSERT' do
    expect { Field.create! }
      .to raise_error \
        /The fields table does not allow INSERT or DELETE or TRUNCATE!/
  end
  it 'raises on DELETE' do
    expect { Field.first.destroy! }
      .to raise_error \
        /The fields table does not allow INSERT or DELETE or TRUNCATE!/
  end
end
