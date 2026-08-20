module Api
  module V1
    # Returns the consolidated savings payload for a single OCID:
    # the latest contract row plus all cashable, non-cashable and
    # non-monetisable savings records. The UI layer reshapes the
    # response for results, CSV export and journey resume.
    class SavingsController < ApplicationController
      def show
        gate_to_ocid(params[:ocid])

        render json: Api::V1::SavingsSerializer.call(CommercialValueTool::SavingsForOcid.call(params[:ocid]))
      end

      def peer_comparison
        gate_to_ocid(params[:ocid])

        render json: Api::V1::PeerComparisonSerializer.call(CommercialValueTool::PeerComparisonForOcid.call(params[:ocid]))
      end

      def update
        contract = gate_to_ocid(params[:ocid])
        CommercialValueTool::UpdateSavings.call(contract: contract, payload: update_params, identity_context: current_identity_context)
        render json: Api::V1::SavingsSerializer.call(CommercialValueTool::SavingsForOcid.call(params[:ocid]))
      end

      def destroy
        saving = gate_to_saving(params[:type], params[:savings_id])
        CommercialValueTool::DeleteSaving.call(saving: saving)
        head :no_content
      end

      def create
        contract = gate_to_ocid(params[:ocid])
        saving = CommercialValueTool::CreateSaving.call(
          contract: contract, type: params[:type], attributes: create_params, identity_context: current_identity_context
        )
        render json: { savings_id: saving.id }, status: :created
      end

      private

      def update_params
        params.permit(:calculation_completed, **CommercialValueTool::SavingsType.permitted_update_params)
      end

      def create_params
        params.permit(*CommercialValueTool::SavingsType.permitted_fields_for(params[:type]))
      end
    end
  end
end
