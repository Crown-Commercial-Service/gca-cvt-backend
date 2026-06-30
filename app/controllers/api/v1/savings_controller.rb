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

      def update
        CommercialValueTool::UpdateSavings.call(ocid: params[:ocid], payload: update_params)
        render json: Api::V1::SavingsSerializer.call(CommercialValueTool::SavingsForOcid.call(params[:ocid]))
      end

      def destroy
        CommercialValueTool::DeleteSaving.call(type: params[:type], savings_id: params[:savings_id])
        head :no_content
      end

      private

      def update_params
        params.permit(
          :calculation_completed,
          cashable_savings: [ :savings_id, :savings_type, :submitted_by_id, :cashable_savings, :baseline_approach, :baseline_value ],
          non_cashable_savings: [ :savings_id, :savings_type, :submitted_by_id, :savings_value ],
          non_monetisable_savings: [ :savings_id, :savings_type, :submitted_by_id ]
        )
      end
    end
  end
end
