module CommercialValueTool
  # Updates an existing savings payload for a single, already org-gated
  # contract. Backs the +PUT /api/v1/savings/:ocid+ endpoint.
  #
  # The payload can carry updates for any combination of cashable,
  # non-cashable and non-monetisable savings, identified per-item by
  # +savings_id+, plus an optional +calculation_completed+ flag for the
  # contract row. The whole update runs inside a single transaction so
  # a missing savings_id or unknown type rolls everything back.
  #
  # Does **not** create new savings records — creation is the POST
  # endpoint's responsibility (CVT-290).
  class UpdateSavings
    class MissingSavingsId < StandardError; end

    # @param contract [Contract] a caller-owned contract
    # @param payload [Hash, ActionController::Parameters]
    # @param identity_context [IdentityContext] the caller's resolved identity
    # @raise [ActiveRecord::RecordNotFound] a referenced savings_id is
    #   missing or belongs to a different OCID
    # @raise [MissingSavingsId] a per-item update did not include a savings_id
    # @raise [ActiveRecord::RecordInvalid] persistence failed
    def self.call(contract:, payload:, identity_context:)
      new(contract: contract, payload: payload, identity_context: identity_context).call
    end

    def initialize(contract:, payload:, identity_context:)
      @contract = contract
      @payload = payload.respond_to?(:to_unsafe_h) ? payload.to_unsafe_h : payload.to_h
      @identity_context = identity_context
    end

    def call
      ActiveRecord::Base.transaction do
        update_contract!
        SavingsType.slugs.each { |slug| update_collection!(slug) }
      end
    end

    private

    def update_contract!
      return unless @payload.key?("calculation_completed") || @payload.key?(:calculation_completed)

      value = @payload["calculation_completed"]
      value = @payload[:calculation_completed] if value.nil?
      @contract.update!(calculation_completed: value)
    end

    def update_collection!(slug)
      key = SavingsType.payload_key_for(slug)
      rows = Array(@payload[key] || @payload[key.to_sym])
      return if rows.empty?

      model = SavingsType.model_for(slug)
      permitted = SavingsType.permitted_fields_for(slug)

      rows.each do |row|
        attrs = row.transform_keys(&:to_s)
        savings_id = attrs["savings_id"] || raise(MissingSavingsId, "Each #{key} update must include a savings_id")
        record = model.for_ocid(@contract.ocid).not_expired.find(savings_id)
        record.update!(attrs.slice(*permitted).merge(submitted_by_id: @identity_context.subject))
      end
    end
  end
end
