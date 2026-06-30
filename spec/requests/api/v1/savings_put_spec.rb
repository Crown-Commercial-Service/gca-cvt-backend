require "rails_helper"

RSpec.describe "PUT /api/v1/savings/:ocid" do
  let!(:contract) { create(:contract, calculation_completed: false) }
  let(:ocid) { contract.ocid }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "updating a single cashable saving" do
    let!(:cashable) do
      create(:cashable_saving, contract: contract,
                               savings_type: "contract_recompete",
                               baseline_approach: "previous_cost",
                               baseline_value: 200_000,
                               submitted_by_id: 1)
    end

    let(:payload) do
      {
        cashable_savings: [
          {
            savings_id: cashable.id,
            savings_type: "volume_reduction",
            baseline_approach: "budget",
            baseline_value: 250_000,
            cashable_savings: true,
            submitted_by_id: 42
          }
        ]
      }
    end

    before { put "/api/v1/savings/#{ocid}", params: payload.to_json, headers: headers }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "persists the updated fields" do
      cashable.reload
      expect(cashable.savings_type).to eq("volume_reduction")
      expect(cashable.baseline_approach).to eq("budget")
      expect(cashable.baseline_value).to eq(250_000)
    end

    it "carries submitted_by_id through to the persisted record" do
      expect(cashable.reload.submitted_by_id).to eq(42)
    end

    it "returns the updated payload mirroring GET" do
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:cashable_savings].first[:baseline_value]).to eq("250000.0")
      expect(body[:data][:cashable_savings].first[:submitted_by_id]).to eq(42)
    end
  end

  describe "updating all three savings types in one request" do
    let!(:cashable) { create(:cashable_saving, contract: contract) }
    let!(:non_cashable) { create(:non_cashable_saving, contract: contract, savings_value: 1_000) }
    let!(:non_monetisable) { create(:non_monetisable_saving, contract: contract, savings_type: "innovation") }

    let(:payload) do
      {
        cashable_savings: [ { savings_id: cashable.id, baseline_value: 999_000, submitted_by_id: 7 } ],
        non_cashable_savings: [ { savings_id: non_cashable.id, savings_value: 8_888, submitted_by_id: 7 } ],
        non_monetisable_savings: [ { savings_id: non_monetisable.id, savings_type: "sustainability", submitted_by_id: 7 } ]
      }
    end

    before { put "/api/v1/savings/#{ocid}", params: payload.to_json, headers: headers }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "persists changes across all three tables" do
      expect(cashable.reload.baseline_value).to eq(999_000)
      expect(non_cashable.reload.savings_value).to eq(8_888)
      expect(non_monetisable.reload.savings_type).to eq("sustainability")
    end
  end

  describe "setting calculation_completed at the final result state" do
    before { put "/api/v1/savings/#{ocid}", params: { calculation_completed: true }.to_json, headers: headers }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "flips calculation_completed on the latest contract row" do
      expect(contract.reload.calculation_completed).to be(true)
    end
  end

  describe "leaving fields not in the payload alone" do
    let!(:cashable) do
      create(:cashable_saving, contract: contract,
                               savings_type: "contract_recompete",
                               baseline_value: 100_000)
    end

    it "preserves savings_type when only baseline_value is updated" do
      put "/api/v1/savings/#{ocid}",
          params: { cashable_savings: [ { savings_id: cashable.id, baseline_value: 250_000 } ] }.to_json,
          headers: headers

      cashable.reload
      expect(cashable.savings_type).to eq("contract_recompete")
      expect(cashable.baseline_value).to eq(250_000)
    end
  end

  describe "isolation between contracts" do
    let(:other_contract) { create(:contract) }
    let!(:other_cashable) { create(:cashable_saving, contract: other_contract, baseline_value: 1) }

    it "returns 404 when savings_id belongs to a different OCID" do
      put "/api/v1/savings/#{ocid}",
          params: { cashable_savings: [ { savings_id: other_cashable.id, baseline_value: 2 } ] }.to_json,
          headers: headers

      expect(response).to have_http_status(:not_found)
      expect(other_cashable.reload.baseline_value).to eq(1)
    end
  end

  describe "transactional behaviour" do
    let!(:cashable_a) { create(:cashable_saving, contract: contract, baseline_value: 10_000) }
    let!(:cashable_b) { create(:cashable_saving, contract: contract, baseline_value: 20_000) }

    it "rolls back earlier updates when a later savings_id is missing" do
      put "/api/v1/savings/#{ocid}", params: {
        cashable_savings: [
          { savings_id: cashable_a.id, baseline_value: 99_999 },
          { savings_id: 999_999_999, baseline_value: 88_888 }
        ]
      }.to_json, headers: headers

      expect(response).to have_http_status(:not_found)
      expect(cashable_a.reload.baseline_value).to eq(10_000)
      expect(cashable_b.reload.baseline_value).to eq(20_000)
    end
  end

  describe "ignoring unpermitted fields" do
    let!(:cashable) { create(:cashable_saving, contract: contract, baseline_value: 5_000) }

    it "does not let callers overwrite ocid, contract_record_id or id" do
      put "/api/v1/savings/#{ocid}", params: {
        cashable_savings: [
          { savings_id: cashable.id, baseline_value: 7_000, ocid: "tampered", contract_record_id: 999, id: 12_345 }
        ]
      }.to_json, headers: headers

      cashable.reload
      expect(cashable.ocid).to eq(ocid)
      expect(cashable.contract_record_id).to eq(contract.record_id)
      expect(cashable.id).not_to eq(12_345)
      expect(cashable.baseline_value).to eq(7_000)
    end
  end

  describe "error responses" do
    it "returns 404 when no contract exists for the OCID" do
      put "/api/v1/savings/ocds-does-not-exist",
          params: { calculation_completed: true }.to_json, headers: headers

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq("not_found")
    end

    it "returns 404 when the savings_id does not exist for the type" do
      put "/api/v1/savings/#{ocid}", params: {
        cashable_savings: [ { savings_id: 999_999_999, baseline_value: 1 } ]
      }.to_json, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when the savings record has been soft-deleted" do
      cashable = create(:cashable_saving, contract: contract, expired_record: true)

      put "/api/v1/savings/#{ocid}", params: {
        cashable_savings: [ { savings_id: cashable.id, baseline_value: 1 } ]
      }.to_json, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 when an item omits savings_id" do
      put "/api/v1/savings/#{ocid}", params: {
        cashable_savings: [ { baseline_value: 1 } ]
      }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq("unprocessable_entity")
    end
  end
end
