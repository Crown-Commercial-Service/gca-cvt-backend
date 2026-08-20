module CommercialValueTool
  # Resolves a caller-owned Contract for an OCID (+gate_ocid+) or a
  # caller-owned savings record via its owning contract (+gate_saving+) —
  # the ownership-gate half of organisation scoping (see
  # Contract::Searchable for the collection half).
  #
  # A miss is always reported to the caller identically, whether the
  # target doesn't exist at all or belongs to a different organisation —
  # this keeps a cross-organisation read indistinguishable from a
  # genuinely nonexistent record, so it can't be used to enumerate another
  # organisation's data. The two cases are still logged separately.
  class OrganisationScope
    # @param ocid [String]
    # @param identity_context [IdentityContext]
    # @return [Contract] the caller-owned contract for the OCID
    # @raise [ActiveRecord::RecordNotFound] the OCID doesn't exist, or belongs to another organisation
    def self.gate_ocid(ocid:, identity_context:)
      contract = Contract.where(ocid: ocid, organisation_id: identity_context.organisation_id)
        .order(record_inserted_date: :desc).first
      return contract if contract

      reason = Contract.exists?(ocid: ocid) ? :out_of_scope : :not_found
      Rails.logger.info(event: "organisation_scope_miss", ocid: ocid, reason: reason)

      raise ActiveRecord::RecordNotFound, "Contract with OCID '#{ocid}' not found"
    end

    # @param type [String] one of {SavingsType.slugs}
    # @param savings_id [Integer, String]
    # @param identity_context [IdentityContext]
    # @return [ApplicationRecord] the caller-owned savings record
    # @raise [ActiveRecord::RecordNotFound] the savings_id doesn't exist, or its contract belongs to another organisation
    def self.gate_saving(type:, savings_id:, identity_context:)
      model = SavingsType.model_for(type)
      saving = model.not_expired
        .joins(:contract)
        .where(id: savings_id, contract: { organisation_id: identity_context.organisation_id })
        .first
      return saving if saving

      reason = model.not_expired.exists?(id: savings_id) ? :out_of_scope : :not_found
      Rails.logger.info(event: "organisation_scope_miss", savings_id: savings_id, type: type, reason: reason)

      raise ActiveRecord::RecordNotFound, "#{type} saving '#{savings_id}' not found"
    end
  end
end
