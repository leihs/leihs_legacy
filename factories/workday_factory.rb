FactoryGirl.define do

  factory :workday do
    inventory_pool
    monday { rand > 0.5 }
    tuesday { rand > 0.5 }
    wednesday { rand > 0.5 }
    thursday { rand > 0.5 }
    friday { rand > 0.5 }
    saturday { rand > 0.5 }
    sunday { rand > 0.5 }
  end

end
