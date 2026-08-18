# frozen_string_literal: true

class PickupLocation < ApplicationRecord
  belongs_to :inventory_pool, inverse_of: :pickup_locations
end
