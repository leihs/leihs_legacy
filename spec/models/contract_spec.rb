require 'rails_helper'

describe Contract do
  it 'closed contract can only have closed reservations' do
    c = FactoryGirl.create(:open_contract)
    expect do
      c.update_attributes!(state: :closed)
    end.to raise_error \
      /all reservations of a closed contract must be closed as well/
  end
end
