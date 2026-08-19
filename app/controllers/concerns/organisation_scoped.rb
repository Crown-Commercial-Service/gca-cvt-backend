module OrganisationScoped
  extend ActiveSupport::Concern

  class NotAppliedError < StandardError; end

  included do
    after_action :verify_organisation_scoped!
  end

  private

  # Marks the current action as having applied organisation scoping,
  # for actions that scope a collection directly (e.g. Contract.search).
  def mark_organisation_scoped!
    @organisation_scoped = true
  end

  # Resolves a caller-owned Contract for an OCID, and marks the current
  # action as having applied organisation scoping.
  #
  # @param ocid [String]
  # @return [CommercialValueTool::Contract]
  # @raise [ActiveRecord::RecordNotFound]
  def gate_to_ocid(ocid)
    contract = CommercialValueTool::OrganisationScope.gate_ocid(ocid: ocid, identity_context: current_identity_context)
    mark_organisation_scoped!
    contract
  end

  def verify_organisation_scoped!
    return if response.status == 401
    return if @organisation_scoped

    raise NotAppliedError, "#{self.class}##{action_name} did not apply organisation scoping"
  end
end
