module CommercialValueTool
  # The sole IdentityResolver implementation for this ticket. Always
  # returns nil, so every real request is denied identity until a real
  # resolver is configured.
  #
  # CVT-293/CVT-308 replace this with a resolver that derives an
  # IdentityContext from real IDAM-derived request identity, swapped in
  # via config/initializers/identity_resolver.rb.
  class NullIdentityResolver
    # @param _request [ActionDispatch::Request]
    # @return [nil]
    def resolve(_request)
      nil
    end
  end
end
