module CommercialValueTool
  # Aggregates the latest contract row plus all three savings collections
  # for a single OCID. Backs the +GET /api/v1/savings/:ocid+ endpoint.
  #
  # Distinguishes "no contract" (contract_found? == false) from
  # "contract but no savings" (any_savings? == false) so callers can
  # surface them differently.
  class SavingsForOcid
    attr_reader :ocid, :contract, :cashable_savings, :non_cashable_savings, :non_monetisable_savings

    # @param ocid [String]
    # @return [SavingsForOcid]
    def self.call(ocid) = new(ocid)

    # @param ocid [String]
    def initialize(ocid)
      @ocid = ocid
      @contract = Contract.latest_for_ocid(ocid)
      @cashable_savings = []
      @non_cashable_savings = []
      @non_monetisable_savings = []
      load_savings if contract_found?
    end

    # @return [Boolean]
    def contract_found? = @contract.present?

    # @return [Boolean]
    def any_savings?
      @cashable_savings.any? || @non_cashable_savings.any? || @non_monetisable_savings.any?
    end

    private

    def load_savings
      @cashable_savings = CashableSaving.for_ocid(ocid).not_expired.order(:id).to_a
      @non_cashable_savings = NonCashableSaving.for_ocid(ocid).not_expired.order(updated_at: :desc).to_a
      @non_monetisable_savings = NonMonetisableSaving.for_ocid(ocid).not_expired.order(updated_at: :desc).to_a
    end
  end
end
