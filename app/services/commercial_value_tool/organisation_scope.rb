module CommercialValueTool
  # Resolves a caller-owned Contract for an OCID, the ownership-gate half
  # of organisation scoping (see Contract::Searchable for the collection
  # half).
  #
  # A miss is always reported to the caller identically, whether the OCID
  # doesn't exist at all or belongs to a different organisation — this
  # keeps a cross-organisation read indistinguishable from a genuinely
  # nonexistent record, so it can't be used to enumerate another
  # organisation's OCIDs. The two cases are still logged separately.
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
  end
end
