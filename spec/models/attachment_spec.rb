require 'rails_helper'

describe Attachment do
  def make_attachment(model: nil, item: nil)
    Attachment.create!(
      model: model,
      item: item,
      content_type: 'application/pdf',
      filename: 'test.pdf',
      size: 100,
      content: Base64.strict_encode64('test')
    )
  end

  def retire(item)
    item.update_columns(retired: 2.years.ago.to_date, retired_reason: 'test')
  end

  def create_reservation(item:, end_date:)
    FactoryBot.create(:closed_contract,
      inventory_pool: item.inventory_pool,
      items: [item],
      start_date: end_date - 1.day,
      end_date: end_date)
  end

  describe '.cleanup_stale!' do
    let(:pool) { FactoryBot.create(:inventory_pool) }
    let(:leihs_model) { FactoryBot.create(:model) }

    def create_item_for(m = leihs_model)
      FactoryBot.create(:item, model: m, inventory_pool: pool, owner: pool)
    end

    context 'model-level attachments' do
      it 'deletes when all items retired and last reservation > 2 years ago' do
        item = create_item_for
        create_reservation(item: item, end_date: 3.years.ago.to_date)
        retire(item)
        att = make_attachment(model: leihs_model)

        Attachment.cleanup_stale!

        expect(Attachment.exists?(att.id)).to be false
      end

      it 'keeps when one item is not retired' do
        retired_item = create_item_for
        create_reservation(item: retired_item, end_date: 3.years.ago.to_date)
        retire(retired_item)
        _active_item = create_item_for
        att = make_attachment(model: leihs_model)

        Attachment.cleanup_stale!

        expect(Attachment.exists?(att.id)).to be true
      end

      it 'keeps when a reservation ended within 2 years' do
        item = create_item_for
        create_reservation(item: item, end_date: 1.year.ago.to_date)
        retire(item)
        att = make_attachment(model: leihs_model)

        Attachment.cleanup_stale!

        expect(Attachment.exists?(att.id)).to be true
      end

      it 'keeps when model has no items' do
        att = make_attachment(model: leihs_model)

        Attachment.cleanup_stale!

        expect(Attachment.exists?(att.id)).to be true
      end
    end

    context 'item-level attachments' do
      it 'deletes when item retired and last reservation > 2 years ago' do
        item = create_item_for
        create_reservation(item: item, end_date: 3.years.ago.to_date)
        retire(item)
        att = make_attachment(item: item)

        Attachment.cleanup_stale!

        expect(Attachment.exists?(att.id)).to be false
      end

      it 'keeps when item is not retired' do
        item = create_item_for
        create_reservation(item: item, end_date: 3.years.ago.to_date)
        att = make_attachment(item: item)

        Attachment.cleanup_stale!

        expect(Attachment.exists?(att.id)).to be true
      end

      it 'keeps when a reservation ended within 2 years' do
        item = create_item_for
        create_reservation(item: item, end_date: 1.year.ago.to_date)
        retire(item)
        att = make_attachment(item: item)

        Attachment.cleanup_stale!

        expect(Attachment.exists?(att.id)).to be true
      end
    end
  end
end
