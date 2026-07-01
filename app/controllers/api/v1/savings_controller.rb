module Api
  module V1
    # Returns the consolidated savings payload for a single OCID:
    # the latest contract row plus all cashable, non-cashable and
    # non-monetisable savings records. The UI layer reshapes the
    # response for results, CSV export and journey resume.
    class SavingsController < ApplicationController
      def show
        result = CommercialValueTool::SavingsForOcid.call(params[:ocid])

        unless result.contract_found?
          raise ActiveRecord::RecordNotFound, "Contract with OCID '#{params[:ocid]}' not found"
        end

        render json: Api::V1::SavingsSerializer.call(result)
      end

      def peer_comparison
        result = CommercialValueTool::PeerComparisonForOcid.call(params[:ocid])

        unless result.contract_found?
          raise ActiveRecord::RecordNotFound, "Contract with OCID '#{params[:ocid]}' not found"
        end

        render json: Api::V1::PeerComparisonSerializer.call(result)
      end

      def destroy
        CommercialValueTool::DeleteSaving.call(type: params[:type], savings_id: params[:savings_id])
        head :no_content
      end
    end
  end
end
