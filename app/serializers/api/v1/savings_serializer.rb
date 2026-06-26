module Api
  module V1
    # Shapes a {CommercialValueTool::SavingsForOcid} result into the
    # API response. Contract is a single object; each savings collection
    # is its own array so the UI can reshape per use case without
    # re-querying.
    class SavingsSerializer
      def self.call(result)
        {
          data: {
            contract: serialize_contract(result.contract),
            cashable_savings: result.cashable_savings.map { |s| serialize_cashable(s) },
            non_cashable_savings: result.non_cashable_savings.map { |s| serialize_non_cashable(s) },
            non_monetisable_savings: result.non_monetisable_savings.map { |s| serialize_non_monetisable(s) }
          }
        }
      end

      class << self
        private

        def serialize_contract(contract)
          {
            record_id: contract.record_id,
            ocid: contract.ocid,
            title: contract.title,
            amount: contract.amount&.to_s,
            currency: contract.currency,
            start_date: contract.start_date&.to_date&.iso8601,
            end_date: contract.end_date&.to_date&.iso8601,
            calculation_completed: contract.calculation_completed,
            description: contract.description,
            cpv_code: contract.cpv_code,
            cpv_description: contract.cpv_description,
            notice_type: contract.notice_type,
            source_api: contract.source_api
          }
        end

        def serialize_cashable(s)
          serialize_common(s).merge(
            cashable_savings: s.cashable_savings,
            baseline_approach: s.baseline_approach,
            baseline_value: s.baseline_value&.to_s
          )
        end

        def serialize_non_cashable(s)
          serialize_common(s).merge(
            savings_value: s.savings_value&.to_s
          )
        end

        def serialize_non_monetisable(s)
          serialize_common(s)
        end

        def serialize_common(s)
          {
            id: s.id,
            ocid: s.ocid,
            contract_record_id: s.contract_record_id,
            savings_type: s.savings_type,
            submitted_by_id: s.submitted_by_id,
            created_at: s.created_at&.iso8601,
            updated_at: s.updated_at&.iso8601
          }
        end
      end
    end
  end
end
