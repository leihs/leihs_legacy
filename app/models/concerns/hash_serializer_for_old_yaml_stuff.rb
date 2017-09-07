module Concerns
  class HashSerializerForOldYamlStuff

    def self.dump(hash)
      YAML.dump(hash || {})
    end

    def self.load(hash)
      hash = YAML.load(hash || '') if hash.is_a?(String)
      (hash || {}).with_indifferent_access
    end
  end
end
