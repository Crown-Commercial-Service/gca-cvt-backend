module CommercialValueTool
  # Immutable value object carrying the caller's resolved identity for a
  # single request. Produced by an IdentityResolver; consumed by
  # OrganisationScope and the organisation-scoping controller concerns.
  IdentityContext = Struct.new(:subject, :organisation_id, :roles, :token_metadata, keyword_init: true) do
    def initialize(*)
      super
      freeze
    end
  end
end
