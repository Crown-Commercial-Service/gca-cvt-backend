require "swagger_helper"

RSpec.describe "api/v1/savings", type: :request do
  path "/api/v1/savings/{ocid}" do
    get "Get all savings for an OCID" do
      tags "Savings"
      produces "application/json"

      parameter name: :ocid, in: :path, type: :string, required: true,
                description: "OCID of the contract whose savings should be returned"

      contract_schema = {
        type: :object,
        required: %w[record_id ocid title calculation_completed],
        properties: {
          record_id: { type: :integer },
          ocid: { type: :string },
          title: { type: :string },
          amount: { type: :string, nullable: true },
          currency: { type: :string, nullable: true },
          start_date: { type: :string, format: :date, nullable: true },
          end_date: { type: :string, format: :date, nullable: true },
          calculation_completed: { type: :boolean },
          description: { type: :string, nullable: true },
          cpv_code: { type: :string, nullable: true },
          cpv_description: { type: :string, nullable: true },
          notice_type: { type: :string, nullable: true },
          source_api: { type: :string, nullable: true }
        }
      }

      common_saving_properties = {
        id: { type: :integer },
        ocid: { type: :string },
        contract_record_id: { type: :integer },
        savings_type: { type: :string },
        submitted_by_id: { type: :integer, nullable: true },
        created_at: { type: :string, format: :"date-time" },
        updated_at: { type: :string, format: :"date-time" }
      }

      cashable_saving_schema = {
        type: :object,
        required: %w[id ocid contract_record_id savings_type cashable_savings baseline_approach],
        properties: common_saving_properties.merge(
          cashable_savings: { type: :boolean },
          baseline_approach: { type: :string },
          baseline_value: { type: :string, nullable: true }
        )
      }

      non_cashable_saving_schema = {
        type: :object,
        required: %w[id ocid contract_record_id savings_type],
        properties: common_saving_properties.merge(
          savings_value: { type: :string, nullable: true }
        )
      }

      non_monetisable_saving_schema = {
        type: :object,
        required: %w[id ocid contract_record_id savings_type],
        properties: common_saving_properties
      }

      success_schema = {
        type: :object,
        required: %w[data],
        properties: {
          data: {
            type: :object,
            required: %w[contract cashable_savings non_cashable_savings non_monetisable_savings],
            properties: {
              contract: contract_schema,
              cashable_savings: { type: :array, items: cashable_saving_schema },
              non_cashable_savings: { type: :array, items: non_cashable_saving_schema },
              non_monetisable_savings: { type: :array, items: non_monetisable_saving_schema }
            }
          }
        }
      }

      error_schema = {
        type: :object,
        required: %w[error],
        properties: {
          error: {
            type: :object,
            required: %w[code message],
            properties: {
              code: { type: :string },
              message: { type: :string }
            }
          }
        }
      }

      response "200", "savings returned for an OCID with all three types of savings" do
        schema(**success_schema)

        let(:contract) { create(:contract) }
        let(:ocid) { contract.ocid }

        before do
          create(:cashable_saving, contract: contract)
          create(:non_cashable_saving, contract: contract)
          create(:non_monetisable_saving, contract: contract)
        end

        run_test!
      end

      response "200", "savings returned for an OCID whose contract has no savings yet" do
        schema(**success_schema)

        let(:contract) { create(:contract) }
        let(:ocid) { contract.ocid }

        run_test!
      end

      response "404", "no contract exists for the given OCID" do
        schema(**error_schema)

        let(:ocid) { "ocds-does-not-exist" }

        run_test!
      end
    end
  end
end
