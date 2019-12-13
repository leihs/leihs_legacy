FactoryGirl.define do

  factory :contract do
    note { Faker::Lorem.paragraph }
    purpose { Faker::Lorem.sentence }
    created_at nil
    inventory_pool { FactoryGirl.create(:inventory_pool) }
    user do
      user = FactoryGirl.create(:user)
      unless AccessRight.find_by(user: user,
                                 inventory_pool: inventory_pool)
        FactoryGirl.create(:access_right,
                           user: user,
                           inventory_pool: inventory_pool,
                           role: :customer)
      end
      user
    end

    transient do
      items do
        Array.new(3).map { |_| FactoryGirl.create(:item) }
      end
      contact_person nil
      start_date nil
      end_date nil
    end

    factory :open_contract do
      state :open

      after :build do |c, evaluator|
        order = FactoryGirl.create(:order,
                                   user: c.user,
                                   inventory_pool: c.inventory_pool,
                                   state: :approved)

        evaluator.items.each do |item|
          c.reservations << \
            FactoryGirl.build(
              :reservation,
              status: :signed,
              inventory_pool: c.inventory_pool,
              user: c.user,
              contract: c,
              order: order,
              start_date: evaluator.start_date,
              end_date: evaluator.end_date,
              item: item,
              model: item.model,
              delegated_user: evaluator.contact_person
            )
        end
      end
    end

    factory :closed_contract do
      state :closed

      after :build do |c, evaluator|
        order = FactoryGirl.create(:order,
                                   user: c.user,
                                   inventory_pool: c.inventory_pool,
                                   state: :approved)

        evaluator.items.each do |item|
          c.reservations << \
            FactoryGirl.build(
              :reservation,
              status: :closed,
              inventory_pool: c.inventory_pool,
              user: c.user,
              contract: c,
              order: order,
              start_date: evaluator.start_date,
              end_date: evaluator.end_date,
              item: item,
              model: item.model,
              delegated_user: evaluator.contact_person
            )
        end
      end
    end
  end

end
