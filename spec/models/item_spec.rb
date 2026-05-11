require 'rails_helper'

describe Item do
  let(:pool) { FactoryBot.create(:inventory_pool) }
  let(:model) { FactoryBot.create(:model) }

  def create_item(code, pool:, created_at: Time.now)
    FactoryBot.create(:item,
      inventory_code: code,
      model: model,
      inventory_pool: pool,
      owner: pool,
      created_at: created_at)
  end

  describe '.proposed_inventory_code' do
    context 'alphabetic shortname' do
      before { pool.update(shortname: 'ABC') }

      it 'proposes 1 when pool has no items' do
        expect(Item.proposed_inventory_code(pool)).to eq('ABC1')
      end

      it 'proposes next after the latest item' do
        create_item('ABC3', pool: pool)
        expect(Item.proposed_inventory_code(pool)).to eq('ABC4')
      end

      it 'fills gap when latest item is before a gap' do
        t = Time.now
        create_item('ABC1', pool: pool, created_at: t)
        create_item('ABC3', pool: pool, created_at: t + 1)
        # latest is ABC3 (created last), so starts at 3 and finds 4
        expect(Item.proposed_inventory_code(pool)).to eq('ABC4')
      end

      it 'fills gap when latest item leaves a gap ahead' do
        t = Time.now
        create_item('ABC3', pool: pool, created_at: t)
        create_item('ABC1', pool: pool, created_at: t + 1)
        # latest is ABC1 (created last), starts at 1 → 1 taken → 2 free
        expect(Item.proposed_inventory_code(pool)).to eq('ABC2')
      end
    end

    context 'numeric shortname' do
      before { pool.update(shortname: '01') }

      it 'proposes first code when pool has no items' do
        expect(Item.proposed_inventory_code(pool)).to eq('011')
      end

      it 'proposes correct next code when shortname is a numeric prefix' do
        create_item('011', pool: pool)
        expect(Item.proposed_inventory_code(pool)).to eq('012')
      end

      it 'proposes correct next after multiple items' do
        t = Time.now
        create_item('011', pool: pool, created_at: t)
        create_item('012', pool: pool, created_at: t + 1)
        expect(Item.proposed_inventory_code(pool)).to eq('013')
      end
    end

    context 'mixed items and packages' do
      before { pool.update(shortname: 'ABC') }

      it 'treats items and packages as a shared sequence' do
        t = Time.now
        create_item('ABC1', pool: pool, created_at: t)
        create_item('P-ABC2', pool: pool, created_at: t + 1)
        create_item('P-ABC3', pool: pool, created_at: t + 2)
        expect(Item.proposed_inventory_code(pool)).to eq('ABC4')
      end
    end

    context 'numeric shortname with mixed items and packages' do
      before { pool.update(shortname: '01') }

      it 'treats items and packages as a shared sequence' do
        t = Time.now
        create_item('011', pool: pool, created_at: t)
        create_item('P-012', pool: pool, created_at: t + 1)
        expect(Item.proposed_inventory_code(pool)).to eq('013')
      end
    end
  end

  describe '.proposed_inventory_code(:lowest)' do
    context 'alphabetic shortname' do
      before { pool.update(shortname: 'ABC') }

      it 'proposes 1 when pool has no items' do
        expect(Item.proposed_inventory_code(pool, :lowest)).to eq('ABC1')
      end

      it 'proposes lowest free number' do
        create_item('ABC1', pool: pool)
        create_item('ABC3', pool: pool)
        expect(Item.proposed_inventory_code(pool, :lowest)).to eq('ABC2')
      end
    end

    context 'numeric shortname' do
      before { pool.update(shortname: '01') }

      it 'does not propose an already-taken code' do
        create_item('011', pool: pool)
        expect(Item.proposed_inventory_code(pool, :lowest)).to eq('012')
      end

      it 'proposes lowest free number with gap' do
        create_item('011', pool: pool)
        create_item('013', pool: pool)
        expect(Item.proposed_inventory_code(pool, :lowest)).to eq('012')
      end
    end
  end

  describe '.proposed_inventory_code(:highest)' do
    context 'alphabetic shortname' do
      before { pool.update(shortname: 'ABC') }

      it 'proposes a number above all existing codes' do
        create_item('ABC3', pool: pool)
        result = Item.proposed_inventory_code(pool, :highest)
        expect(result).to match(/\AABC\d+\z/)
        expect(result).not_to eq('ABC3')
      end
    end
  end
end
