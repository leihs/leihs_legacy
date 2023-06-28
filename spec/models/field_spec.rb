require 'rails_helper'

describe Field do

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
