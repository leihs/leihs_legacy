unless Rails.env.production?
  ActiveSupport::Deprecation.behavior = :raise
end
