module Api
  module V1
    # Converts a Contract::SearchResults into the API response hash.
    class ContractSerializer
      def self.call(results)
        {
          data: results.map { |c| serialize_contract(c) },
          meta: {
            page: results.current_page,
            total_pages: results.total_pages,
            total_count: results.total_count,
            per_page: results.limit_value,
            sort_column: results.sort_column,
            sort_direction: results.sort_direction
          }
        }
      end

      def self.serialize_contract(contract)
        {
          record_id: contract.record_id,
          title: contract.title,
          ocid: contract.ocid,
          amount: contract.amount&.to_s,
          start_date: contract.start_date&.to_date&.iso8601,
          end_date: contract.end_date&.to_date&.iso8601,
          status: contract.status
        }
      end
      private_class_method :serialize_contract
    end
  end
end
