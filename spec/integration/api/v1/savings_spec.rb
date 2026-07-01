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

  path "/api/v1/savings/{ocid}/peer-comparison" do
    get "Get peer-group comparison for an OCID's cashable savings" do
      tags "Savings"
      produces "application/json"

      parameter name: :ocid, in: :path, type: :string, required: true,
                description: "OCID of the contract to compare against its peer group"

      average_schema = {
        type: :object,
        required: %w[mean median absolute_mean absolute_median],
        properties: {
          mean: { type: :number, nullable: true },
          median: { type: :number, nullable: true },
          absolute_mean: { type: :string, nullable: true },
          absolute_median: { type: :string, nullable: true }
        }
      }

      peer_comparison_success_schema = {
        type: :object,
        required: %w[data],
        properties: {
          data: {
            type: :object,
            required: %w[contract_approach contract_percentage contract_absolute_value available_approaches peer_group_averages],
            properties: {
              contract_approach: { type: :string, nullable: true },
              contract_percentage: { type: :number, nullable: true },
              contract_absolute_value: { type: :string, nullable: true },
              available_approaches: { type: :array, items: { type: :string } },
              peer_group_averages: {
                type: :object,
                additionalProperties: average_schema
              }
            }
          }
        }
      }

      peer_comparison_error_schema = {
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

      response "200", "peer comparison returned for an OCID with peers" do
        schema(**peer_comparison_success_schema)

        let(:contract) { create(:contract, :completed, amount: 100_000) }
        let(:ocid) { contract.ocid }

        before do
          create(:cashable_saving, contract: contract, baseline_approach: "previous_cost", baseline_value: 120_000)
          peer = create(:contract, :completed, amount: 100_000)
          create(:cashable_saving, contract: peer, baseline_approach: "previous_cost", baseline_value: 130_000)
        end

        run_test!
      end

      response "404", "no contract exists for the given OCID" do
        schema(**peer_comparison_error_schema)

        let(:ocid) { "ocds-does-not-exist" }

        run_test!
      end
    end
  end

  path "/api/v1/savings/{type}/{savings_id}" do
    delete "Soft-delete a single savings record" do
      tags "Savings"
      produces "application/json"

      parameter name: :type, in: :path, type: :string, required: true,
                enum: %w[cashable non-cashable non-monetisable],
                description: "Savings record type"
      parameter name: :savings_id, in: :path, type: :integer, required: true,
                description: "Identifier of the savings record to delete"

      delete_error_schema = {
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

      response "204", "savings record soft-deleted" do
        let(:contract) { create(:contract) }
        let(:saving) { create(:cashable_saving, contract: contract) }
        let(:type) { "cashable" }
        let(:savings_id) { saving.id }

        run_test!
      end

      response "404", "no active savings record matches the given type and id" do
        schema(**delete_error_schema)

        let(:type) { "cashable" }
        let(:savings_id) { 999_999_999 }

        run_test!
      end
    end
  end
end
