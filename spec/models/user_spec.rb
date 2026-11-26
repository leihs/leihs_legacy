require 'rails_helper'

describe User do
  before :example do
    @inventory_pool = FactoryBot.create(:inventory_pool)
    @item = FactoryBot.create(:item, owner: @inventory_pool)
  end

  def create_signed_reservation(end_date:, sent_back_to_main_location_at: nil)
    contract = FactoryBot.create(:open_contract,
                                  inventory_pool: @inventory_pool,
                                  items: [@item],
                                  start_date: 5.days.ago.to_date,
                                  end_date: end_date)
    reservation = contract.reservations.first
    reservation.update_columns(
      sent_back_to_main_location_at: sent_back_to_main_location_at
    )
    reservation
  end

  describe '.remind_and_suspend_all' do
    it 'reminds and suspends for an overdue reservation not dropped off at a pickup location' do
      reservation = create_signed_reservation(end_date: 2.days.ago.to_date)
      @inventory_pool.update!(automatic_suspension: true,
                               automatic_suspension_reason: 'overdue')

      expect(Mailer).to receive(:remind_user)
        .with(reservation.user, [reservation], anything)

      User.remind_and_suspend_all

      expect(Suspension.where(user: reservation.user,
                               inventory_pool: @inventory_pool)).to exist
    end

    it 'does not remind or suspend for an overdue reservation dropped off at a pickup location' do
      reservation = create_signed_reservation(end_date: 2.days.ago.to_date,
                                               sent_back_to_main_location_at: 1.day.ago)
      @inventory_pool.update!(automatic_suspension: true,
                               automatic_suspension_reason: 'overdue')

      expect(Mailer).not_to receive(:remind_user)

      User.remind_and_suspend_all

      expect(Suspension.where(user: reservation.user,
                               inventory_pool: @inventory_pool)).not_to exist
    end
  end

  describe '.send_deadline_soon_reminder_to_everybody' do
    it 'sends a deadline soon reminder for a reservation not dropped off at a pickup location' do
      reservation = create_signed_reservation(end_date: Date.tomorrow)

      expect(Mailer).to receive(:deadline_soon_reminder)
        .with(reservation.user, [reservation], anything)

      User.send_deadline_soon_reminder_to_everybody
    end

    it 'does not send a deadline soon reminder for a reservation dropped off at a pickup location' do
      create_signed_reservation(end_date: Date.tomorrow,
                                 sent_back_to_main_location_at: 1.hour.ago)

      expect(Mailer).not_to receive(:deadline_soon_reminder)

      User.send_deadline_soon_reminder_to_everybody
    end
  end
end
