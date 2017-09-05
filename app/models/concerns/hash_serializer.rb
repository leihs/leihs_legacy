module Concerns
  class HashSerializer
    def self.dump(hash)
      hash
    end

    def self.load(hash)
      return unless hash
      hash.with_indifferent_access
    end
  end
end
