module CommercialValueTool
  # Compares a single contract's cashable saving against server-side
  # peer-group aggregates (mean/median, percentage/absolute), grouped
  # by baseline approach. Backs the +GET /api/v1/savings/:ocid/peer-comparison+
  # endpoint.
  #
  # The peer group is "all contracts" (no CPV filter), excluding the
  # target contract's own row, and limited to peers with a completed
  # calculation, a positive amount, and a non-expired cashable saving.
  class PeerComparisonForOcid
    PeerGroupAverage = Struct.new(:mean, :median, :absolute_mean, :absolute_median, keyword_init: true)

    PEER_GROUP_SQL = <<~SQL.freeze
      WITH latest_contracts AS (
        SELECT DISTINCT ON (ocid) ocid, amount
        FROM contracts
        WHERE expired_record IS NOT TRUE
          AND calculation_completed = true
          AND amount IS NOT NULL
          AND amount > 0
        ORDER BY ocid, record_inserted_date DESC
      )
      SELECT
        cs.baseline_approach,
        AVG((cs.baseline_value - lc.amount) / lc.amount * 100)            AS mean,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
          ORDER BY (cs.baseline_value - lc.amount) / lc.amount * 100
        )                                                                  AS median,
        AVG(cs.baseline_value - lc.amount)                                AS absolute_mean,
        PERCENTILE_CONT(0.5) WITHIN GROUP (
          ORDER BY (cs.baseline_value - lc.amount)
        )                                                                  AS absolute_median
      FROM cashable_savings cs
      JOIN latest_contracts lc ON lc.ocid = cs.ocid
      WHERE cs.expired_record IS NOT TRUE
        AND cs.ocid != ?
        AND cs.baseline_value IS NOT NULL
      GROUP BY cs.baseline_approach
    SQL
    private_constant :PEER_GROUP_SQL

    attr_reader :ocid

    def self.call(ocid) = new(ocid)

    def initialize(ocid)
      @ocid = ocid
      @contract = Contract.latest_for_ocid(ocid)
    end

    def contract_found? = @contract.present?

    def contract_approach = contract_saving&.baseline_approach

    def contract_percentage
      return nil unless contract_saving&.baseline_value&.positive? && contract_amount

      ((contract_saving.baseline_value - contract_amount) / contract_saving.baseline_value * 100).to_f.round(1)
    end

    def contract_absolute_value
      return nil unless contract_saving&.baseline_value && contract_amount

      contract_saving.baseline_value - contract_amount
    end

    def peer_group_averages
      @peer_group_averages ||= ActiveRecord::Base.connection
        .select_all(ActiveRecord::Base.sanitize_sql_array([ PEER_GROUP_SQL, ocid ]))
        .each_with_object({}) do |row, hash|
          hash[row["baseline_approach"]] = PeerGroupAverage.new(
            mean: row["mean"]&.to_f&.round(1),
            median: row["median"]&.to_f&.round(1),
            absolute_mean: row["absolute_mean"] && BigDecimal(row["absolute_mean"].to_s).round(2),
            absolute_median: row["absolute_median"] && BigDecimal(row["absolute_median"].to_s).round(2)
          )
        end
    end

    def available_approaches = peer_group_averages.keys

    private

    def contract_saving
      @contract_saving ||= CashableSaving.for_ocid(ocid).not_expired.order(:id).first
    end

    def contract_amount = @contract&.amount
  end
end
