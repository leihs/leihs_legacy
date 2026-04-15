# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MINOR-OPT SQL / method injection hardening' do
  describe 'Visit.search' do
    it 'escapes quotes in search tokens (no SQL breakout in EXISTS subquery)' do
      sql = Visit.search("foo'bar").to_sql
      expect(sql).not_to include("ILIKE 'foo'bar")
      expect(sql).to include("ILIKE")
      expect(sql).to include("foo''bar")
    end
  end

  describe 'Option.filter' do
    let(:pool) { FactoryBot.create(:inventory_pool) }

    it 'ignores non-allowlisted sort column names' do
      sql = Option.filter(
        { sort: 'id; SELECT 1', order: 'desc', paginate: 'false' },
        pool
      ).to_sql
      expect(sql).not_to match(/id; SELECT/i)
      expect(sql).to match(/ORDER BY.*name.*DESC/i)
    end

    it 'allows only asc/desc for order direction' do
      sql = Option.filter(
        { sort: 'product', order: 'DESC; DROP TABLE options', paginate: 'false' },
        pool
      ).to_sql
      expect(sql).not_to match(/DROP TABLE/i)
      expect(sql).to match(/ORDER BY.*product.*ASC/i)
    end
  end

  describe 'Template.filter' do
    let(:pool) { FactoryBot.create(:inventory_pool) }

    it 'falls back to allowlisted sort for malicious sort param' do
      sql = Template.filter(
        { sort: 'id; SELECT 1', order: 'desc', page: 1 },
        pool
      ).to_sql
      expect(sql).not_to match(/id; SELECT/i)
      expect(sql).to match(/ORDER BY.*name.*DESC/i)
    end
  end

  describe 'User.filter' do
    let(:pool) { FactoryBot.create(:inventory_pool) }
    let!(:user) { FactoryBot.create(:user) }

    before do
      AccessRight.create!(user: user, inventory_pool: pool, role: 'inventory_manager')
    end

    it 'does not invoke arbitrary relation methods via params[:role]' do
      expect do
        User.filter({ role: 'delete_all' }, pool).load
      end.not_to change(User, :count)
    end

    it 'applies only allowlisted role scopes' do
      rel = User.filter({ role: 'inventory_managers' }, pool)
      expect(rel.to_sql).to include('inventory_manager')
    end
  end

  describe 'Room.search' do
    it 'does not interpolate the search term into raw SQL' do
      sql = Room.search("x'y").to_sql
      expect(sql).not_to include("ILIKE '%x'y%'")
      expect(sql).to include('ILIKE')
    end
  end

  describe 'Entitlement.query' do
    it 'embeds UUIDs via sanitization (no raw string concatenation from callers)' do
      id = SecureRandom.uuid
      pool_id = SecureRandom.uuid
      sql = Entitlement.query(model_ids: [id], inventory_pool_id: pool_id)
      expect(sql).to include(id)
      expect(sql).to include(pool_id)
      expect(sql).not_to match(/IN\s*\(\s*'[^']*'\s*''/m)
    end
  end
end
