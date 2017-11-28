require 'rails_helper'
require "#{Rails.root}/features/support/dataset"

describe Contract do

  it 'closed contract can only have closed reservations' do
    c = FactoryGirl.create(:open_contract)
    expect do
      c.update_attributes!(state: :closed)
    end.to raise_error \
      /all reservations of a closed contract must be closed as well/
  end

  context 'search and filter' do
    before :all do
      ::Dataset.restore_dump
      user = User.find_by(login: 'normin')
      @inventory_pool = InventoryPool.find_by(name: 'IT-Ausleihe')
      Contract.update_all(user_id: user.id, inventory_pool_id: @inventory_pool.id)
      @real_count = Contract
                    .where(user: user, inventory_pool: @inventory_pool).count
      expect(@real_count).to be > 5
    end

    example '`search` scope can be counted' do
      pending 'crashes with SQL error!'
      # NOTE: uses `search` method to check the unpaginated scope
      scope = Contract.search('Normin Normalo')
      expect(scope.count).to be > 5
    end

    example 'search results are counted correctly with pagination' do
      pending 'wrong count because of uncountable query!'
      # NOTE:
      # - uses `filter` method like the controller action.
      # - returns already paginated collection, se `will_paginate` method to check!
      result = Contract
               .filter({ search_term: 'Normin Normalo' }, nil, @inventory_pool)
      expect(result.total_entries).to eq @real_count
    end
  end

end
