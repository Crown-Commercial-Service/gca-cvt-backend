module CommercialValueTool
  # Creates a new savings record for the given OCID and +type+ slug.
  # Backs the +POST /api/v1/savings/:ocid+ endpoint.
  #
  # Always inserts a fresh row — never upserts. The UI app decides whether
  # to POST (create) or PUT (update) based on its journey state.
  class CreateSaving
    TYPE_MODELS = {
      "cashable" => CashableSaving,
      "non-cashable" => NonCashableSaving,
      "non-monetisable" => NonMonetisableSaving
    }.freeze

    PERMITTED_FIELDS = {
      "cashable" => %w[savings_type submitted_by_id cashable_savings baseline_approach baseline_value].freeze,
      "non-cashable" => %w[savings_type submitted_by_id savings_value].freeze,
      "non-monetisable" => %w[savings_type submitted_by_id].freeze
    }.freeze

    class UnknownType < StandardError; end

    # @param ocid [String]
    # @param type [String] one of the keys in {TYPE_MODELS}
    # @param attributes [Hash, ActionController::Parameters]
    # @return [CommercialValueTool::CashableSaving,
    #         CommercialValueTool::NonCashableSaving,
    #         CommercialValueTool::NonMonetisableSaving]
    # @raise [ActiveRecord::RecordNotFound] OCID has no contract
    # @raise [UnknownType] +type+ is not a recognised savings type
    # @raise [ActiveRecord::RecordInvalid] persistence failed
    def self.call(ocid:, type:, attributes:)
      new(ocid: ocid, type: type, attributes: attributes).call
    end

    def initialize(ocid:, type:, attributes:)
      @ocid = ocid
      @type = type.to_s
      @attributes = normalise(attributes)
    end

    def call
      model = TYPE_MODELS.fetch(@type) { raise UnknownType, "Unknown savings type '#{@type}'" }
      permitted = PERMITTED_FIELDS.fetch(@type)

      model.create!(@attributes.slice(*permitted).merge(
        ocid: @ocid,
        contract_record_id: contract.record_id
      ))
    end

    private

    def contract
      @contract ||= Contract.latest_for_ocid(@ocid) ||
        raise(ActiveRecord::RecordNotFound, "Contract with OCID '#{@ocid}' not found")
    end

    def normalise(attributes)
      hash = attributes.respond_to?(:to_unsafe_h) ? attributes.to_unsafe_h : attributes.to_h
      hash.transform_keys(&:to_s)
    end
  end
end
