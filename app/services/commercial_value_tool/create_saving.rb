module CommercialValueTool
  # Creates a single new savings record for an already org-gated contract.
  # Backs the +POST /api/v1/savings/:ocid/:type+ endpoint.
  #
  # Unlike +UpdateSavings+, this always inserts a new row — it never
  # matches against an existing record, even if one of the same type
  # already exists for the OCID.
  class CreateSaving
    # @param contract [Contract] a caller-owned contract
    # @param type [String] one of {SavingsType.slugs}
    # @param attributes [Hash, ActionController::Parameters]
    # @param identity_context [IdentityContext] the caller's resolved identity
    # @return [ApplicationRecord] the newly created savings record
    # @raise [CommercialValueTool::UnknownSavingsType] +type+ is not a recognised savings type
    # @raise [ActiveRecord::RecordInvalid] persistence failed
    def self.call(contract:, type:, attributes:, identity_context:)
      new(contract: contract, type: type, attributes: attributes, identity_context: identity_context).call
    end

    def initialize(contract:, type:, attributes:, identity_context:)
      @contract = contract
      @type = type.to_s
      @attributes = attributes.respond_to?(:to_unsafe_h) ? attributes.to_unsafe_h : attributes.to_h
      @identity_context = identity_context
    end

    def call
      attrs = @attributes.transform_keys(&:to_s)
      model.create!(
        attrs.slice(*permitted).merge(
          ocid: @contract.ocid,
          contract_record_id: @contract.record_id,
          submitted_by_id: @identity_context.subject,
          represented_organisation_id: @identity_context.organisation_id
        )
      )
    end

    private

    def model
      SavingsType.model_for(@type)
    end

    def permitted
      SavingsType.permitted_fields_for(@type)
    end
  end
end
