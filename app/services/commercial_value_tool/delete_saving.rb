module CommercialValueTool
  # Soft-deletes a single, already org-gated savings record. Backs the
  # +DELETE /api/v1/savings/:type/:savings_id+ endpoint.
  #
  # "Soft delete" here means setting +expired_record+ to +true+; the
  # +Saving#not_expired+ scope then hides the row from subsequent reads.
  class DeleteSaving
    # @param saving [ApplicationRecord] a caller-owned savings record
    # @return [void]
    def self.call(saving:)
      new(saving: saving).call
    end

    def initialize(saving:)
      @saving = saving
    end

    def call
      @saving.update!(expired_record: true)
    end
  end
end
