module CommercialValueTool
  # Creates a single new savings record for an OCID. Backs the
  # +POST /api/v1/savings/:ocid/:type+ endpoint.
  #
  # Unlike +UpdateSavings+, this always inserts a new row — it never
  # matches against an existing record, even if one of the same type
  # already exists for the OCID.
  class CreateSaving
    # @param ocid [String]
    # @param type [String] one of {SavingsType.slugs}
    # @param attributes [Hash, ActionController::Parameters]
    # @return [ApplicationRecord] the newly created savings record
    # @raise [CommercialValueTool::UnknownSavingsType] +type+ is not a recognised savings type
    # @raise [ActiveRecord::RecordNotFound] OCID has no contract
    # @raise [ActiveRecord::RecordInvalid] persistence failed
    def self.call(ocid:, type:, attributes:)
      new(ocid: ocid, type: type, attributes: attributes).call
    end

    def initialize(ocid:, type:, attributes:)
      @ocid = ocid
      @type = type.to_s
      @attributes = attributes.respond_to?(:to_unsafe_h) ? attributes.to_unsafe_h : attributes.to_h
    end

    def call
      attrs = @attributes.transform_keys(&:to_s)
      model.create!(attrs.slice(*permitted).merge(ocid: @ocid, contract_record_id: contract.record_id))
    end

    private

    def model
      SavingsType.model_for(@type)
    end

    def permitted
      SavingsType.permitted_fields_for(@type)
    end

    def contract
      @contract ||= Contract.latest_for_ocid(@ocid) ||
        raise(ActiveRecord::RecordNotFound, "Contract with OCID '#{@ocid}' not found")
    end
  end
end
