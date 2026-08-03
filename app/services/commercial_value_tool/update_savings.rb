module CommercialValueTool
  # Updates an existing savings payload for a single OCID. Backs the
  # +PUT /api/v1/savings/:ocid+ endpoint.
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

    # @param ocid [String]
    # @param payload [Hash, ActionController::Parameters]
    # @raise [ActiveRecord::RecordNotFound] OCID has no contract, or a
    #   referenced savings_id is missing or belongs to a different OCID
    # @raise [MissingSavingsId] a per-item update did not include a savings_id
    # @raise [ActiveRecord::RecordInvalid] persistence failed
    def self.call(ocid:, payload:)
      new(ocid: ocid, payload: payload).call
    end

    def initialize(ocid:, payload:)
      @ocid = ocid
      @payload = payload.respond_to?(:to_unsafe_h) ? payload.to_unsafe_h : payload.to_h
    end

    def call
      ActiveRecord::Base.transaction do
        update_contract!
        SavingsType.slugs.each { |slug| update_collection!(slug) }
      end
    end

    private

    def contract
      @contract ||= Contract.latest_for_ocid(@ocid) ||
        raise(ActiveRecord::RecordNotFound, "Contract with OCID '#{@ocid}' not found")
    end

    def update_contract!
      return unless @payload.key?("calculation_completed") || @payload.key?(:calculation_completed)

      value = @payload["calculation_completed"]
      value = @payload[:calculation_completed] if value.nil?
      contract.update!(calculation_completed: value)
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
        record = model.for_ocid(@ocid).not_expired.find(savings_id)
        record.update!(attrs.slice(*permitted))
      end
    end
  end
end
