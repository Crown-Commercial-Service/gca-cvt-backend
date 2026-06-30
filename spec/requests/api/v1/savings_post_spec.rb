require "rails_helper"

RSpec.describe "POST /api/v1/savings/:ocid" do
  let!(:contract) { create(:contract) }
  let(:ocid) { contract.ocid }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "creating a cashable saving" do
    let(:payload) do
      {
        type: "cashable",
        saving: {
          savings_type: "contract_recompete",
          submitted_by_id: 42,
          cashable_savings: true,
          baseline_approach: "previous_cost",
          baseline_value: 250_000
        }
      }
    end

    before { post "/api/v1/savings/#{ocid}", params: payload.to_json, headers: headers }

    it "returns 201 Created" do
      expect(response).to have_http_status(:created)
    end

    it "returns the generated savings_id and type" do
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:type]).to eq("cashable")
      expect(body[:data][:savings_id]).to be_a(Integer)
      expect(body[:data][:savings_id]).to eq(CommercialValueTool::CashableSaving.last.id)
    end

    it "persists all permitted fields" do
      saving = CommercialValueTool::CashableSaving.last
      expect(saving.savings_type).to eq("contract_recompete")
      expect(saving.cashable_savings).to be(true)
      expect(saving.baseline_approach).to eq("previous_cost")
      expect(saving.baseline_value).to eq(250_000)
    end

    it "carries submitted_by_id through to the persisted record" do
      expect(CommercialValueTool::CashableSaving.last.submitted_by_id).to eq(42)
    end

    it "sets ocid and contract_record_id from the URL, not the payload" do
      saving = CommercialValueTool::CashableSaving.last
      expect(saving.ocid).to eq(ocid)
      expect(saving.contract_record_id).to eq(contract.record_id)
    end
  end

  describe "creating a non-cashable saving" do
    let(:payload) do
      {
        type: "non-cashable",
        saving: {
          savings_type: "process_improvement",
          submitted_by_id: 7,
          savings_value: 12_500
        }
      }
    end

    before { post "/api/v1/savings/#{ocid}", params: payload.to_json, headers: headers }

    it "returns 201 with the generated id" do
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:type]).to eq("non-cashable")
      expect(body[:data][:savings_id]).to eq(CommercialValueTool::NonCashableSaving.last.id)
    end

    it "persists savings_value and submitted_by_id" do
      saving = CommercialValueTool::NonCashableSaving.last
      expect(saving.savings_value).to eq(12_500)
      expect(saving.submitted_by_id).to eq(7)
    end
  end

  describe "creating a non-monetisable saving" do
    let(:payload) do
      {
        type: "non-monetisable",
        saving: {
          savings_type: "sustainability",
          submitted_by_id: 9
        }
      }
    end

    before { post "/api/v1/savings/#{ocid}", params: payload.to_json, headers: headers }

    it "returns 201 with the generated id" do
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:type]).to eq("non-monetisable")
      expect(body[:data][:savings_id]).to eq(CommercialValueTool::NonMonetisableSaving.last.id)
    end

    it "persists savings_type and submitted_by_id" do
      saving = CommercialValueTool::NonMonetisableSaving.last
      expect(saving.savings_type).to eq("sustainability")
      expect(saving.submitted_by_id).to eq(9)
    end
  end

  describe "always creates a new record for non-cashable and non-monetisable" do
    let!(:existing_non_cashable) { create(:non_cashable_saving, contract: contract, savings_value: 1) }
    let!(:existing_non_monetisable) { create(:non_monetisable_saving, contract: contract) }

    it "inserts a second non-cashable row rather than updating the existing one" do
      expect {
        post "/api/v1/savings/#{ocid}",
             params: { type: "non-cashable", saving: { savings_value: 999 } }.to_json,
             headers: headers
      }.to change { CommercialValueTool::NonCashableSaving.where(ocid: ocid).count }.by(1)

      expect(existing_non_cashable.reload.savings_value).to eq(1)
    end

    it "inserts a second non-monetisable row rather than updating the existing one" do
      expect {
        post "/api/v1/savings/#{ocid}",
             params: { type: "non-monetisable", saving: { savings_type: "innovation" } }.to_json,
             headers: headers
      }.to change { CommercialValueTool::NonMonetisableSaving.where(ocid: ocid).count }.by(1)
    end
  end

  describe "ignoring unpermitted fields" do
    it "does not let callers overwrite ocid, contract_record_id or id" do
      post "/api/v1/savings/#{ocid}", params: {
        type: "cashable",
        saving: {
          savings_type: "contract_recompete",
          cashable_savings: true,
          baseline_approach: "previous_cost",
          baseline_value: 100,
          ocid: "tampered",
          contract_record_id: 999_999,
          id: 12_345,
          expired_record: true
        }
      }.to_json, headers: headers

      saving = CommercialValueTool::CashableSaving.last
      expect(saving.ocid).to eq(ocid)
      expect(saving.contract_record_id).to eq(contract.record_id)
      expect(saving.id).not_to eq(12_345)
    end
  end

  describe "error responses" do
    it "returns 404 when no contract exists for the OCID" do
      post "/api/v1/savings/ocds-does-not-exist",
           params: { type: "cashable", saving: { savings_type: "x", cashable_savings: true, baseline_approach: "y" } }.to_json,
           headers: headers

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq("not_found")
    end

    it "returns 422 when the type is unknown" do
      post "/api/v1/savings/#{ocid}",
           params: { type: "mystery", saving: { savings_type: "x" } }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq("unprocessable_entity")
      expect(body[:error][:message]).to match(/mystery/)
    end

    it "returns 422 when the type field is omitted entirely" do
      post "/api/v1/savings/#{ocid}",
           params: { saving: { savings_type: "x" } }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq("unprocessable_entity")
    end

    it "does not persist anything when the type is unknown" do
      expect {
        post "/api/v1/savings/#{ocid}",
             params: { type: "mystery", saving: { savings_type: "x" } }.to_json,
             headers: headers
      }.not_to change(CommercialValueTool::CashableSaving, :count)
    end
  end
end
