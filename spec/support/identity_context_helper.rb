module IdentityContextHelper
  def stub_identity_context(organisation_id:, subject: "test-subject", roles: [])
    identity_context = CommercialValueTool::IdentityContext.new(
      subject: subject, organisation_id: organisation_id, roles: roles, token_metadata: {}
    )

    allow(Rails.application.config.x.identity_resolver).to receive(:resolve).and_return(identity_context)
  end
end

RSpec.configure do |config|
  config.include IdentityContextHelper, type: :request
end
