module CommercialValueTool
  # Soft-deletes a single savings record identified by its +type+ slug
  # (cashable, non-cashable, non-monetisable) and +savings_id+. Backs the
  # +DELETE /api/v1/savings/:type/:savings_id+ endpoint.
  #
  # "Soft delete" here means setting +expired_record+ to +true+; the
  # +Saving#not_expired+ scope then hides the row from subsequent reads.
  class DeleteSaving
    TYPE_MODELS = {
      "cashable" => CashableSaving,
      "non-cashable" => NonCashableSaving,
      "non-monetisable" => NonMonetisableSaving
    }.freeze

    # @param type [String] one of the keys in {TYPE_MODELS}
    # @param savings_id [Integer, String]
    # @return [void]
    # @raise [KeyError] if +type+ is not a recognised savings type
    # @raise [ActiveRecord::RecordNotFound] if no active record matches
    def self.call(type:, savings_id:)
      new(type: type, savings_id: savings_id).call
    end

    def initialize(type:, savings_id:)
      @type = type
      @savings_id = savings_id
    end

    def call
      TYPE_MODELS.fetch(@type).not_expired.find(@savings_id).update!(expired_record: true)
    end
  end
end
