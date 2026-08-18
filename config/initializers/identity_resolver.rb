Rails.application.config.to_prepare do
  Rails.application.config.x.identity_resolver = CommercialValueTool::NullIdentityResolver.new
end
