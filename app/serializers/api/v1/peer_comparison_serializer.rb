module Api
  module V1
    # Shapes a {CommercialValueTool::PeerComparisonForOcid} result into the
    # API response.
    class PeerComparisonSerializer
      def self.call(result)
        {
          data: {
            contract_approach: result.contract_approach,
            contract_percentage: result.contract_percentage,
            contract_absolute_value: result.contract_absolute_value&.to_s,
            available_approaches: result.available_approaches,
            peer_group_averages: result.peer_group_averages.transform_values { |avg| serialize_average(avg) }
          }
        }
      end

      class << self
        private

        def serialize_average(avg)
          {
            mean: avg.mean,
            median: avg.median,
            absolute_mean: avg.absolute_mean&.to_s,
            absolute_median: avg.absolute_median&.to_s
          }
        end
      end
    end
  end
end
