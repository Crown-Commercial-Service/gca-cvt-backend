require "rails_helper"

RSpec.describe "POST /api/v1/savings/:ocid/:type" do
  let!(:contract) { create(:contract) }
  let(:ocid) { contract.ocid }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  shared_examples "a savings creation endpoint" do |type:, model:, payload:|
    it "returns 201 with a savings_id" do
      post "/api/v1/savings/#{ocid}/#{type}", params: payload.to_json, headers: headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:savings_id]).to eq(model.last.id)
    end

    it "persists the supplied fields and submitted_by_id" do
      expect {
        post "/api/v1/savings/#{ocid}/#{type}", params: payload.to_json, headers: headers
      }.to change(model, :count).by(1)

      record = model.last
      payload.each do |key, value|
        expect(record.public_send(key)).to eq(value)
      end
    end

    it "inserts a new row rather than updating an existing record of the same type" do
      existing = create(model.name.demodulize.underscore.to_sym, contract: contract)

      expect {
        post "/api/v1/savings/#{ocid}/#{type}", params: payload.to_json, headers: headers
      }.to change(model, :count).by(1)

      expect(existing.reload.attributes).to eq(existing.attributes)
    end

    it "ignores caller-supplied ocid, contract_record_id and id" do
      tampered_payload = payload.merge(ocid: "tampered", contract_record_id: 999_999, id: 12_345)

      post "/api/v1/savings/#{ocid}/#{type}", params: tampered_payload.to_json, headers: headers

      record = model.last
      expect(record.ocid).to eq(ocid)
      expect(record.contract_record_id).to eq(contract.record_id)
      expect(record.id).not_to eq(12_345)
    end
  end

  context "when the type is cashable" do
    it_behaves_like "a savings creation endpoint",
                    type: "cashable",
                    model: CommercialValueTool::CashableSaving,
                    payload: {
                      savings_type: "volume_reduction",
                      baseline_approach: "budget",
                      baseline_value: 250_000,
                      cashable_savings: true,
                      submitted_by_id: 42
                    }
  end

  context "when the type is non-cashable" do
    it_behaves_like "a savings creation endpoint",
                    type: "non-cashable",
                    model: CommercialValueTool::NonCashableSaving,
                    payload: {
                      savings_type: "social_value",
                      savings_value: 8_888,
                      submitted_by_id: 42
                    }
  end

  context "when the type is non-monetisable" do
    it_behaves_like "a savings creation endpoint",
                    type: "non-monetisable",
                    model: CommercialValueTool::NonMonetisableSaving,
                    payload: {
                      savings_type: "innovation",
                      submitted_by_id: 42
                    }
  end

  describe "error responses" do
    it "returns 404 when no contract exists for the OCID" do
      post "/api/v1/savings/ocds-does-not-exist/cashable",
           params: { savings_type: "innovation", submitted_by_id: 1 }.to_json, headers: headers

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq("not_found")
      expect(CommercialValueTool::CashableSaving.count).to eq(0)
    end

    it "returns 404 when the type is not a recognised savings type" do
      expect {
        post "/api/v1/savings/#{ocid}/bogus-type",
             params: { savings_type: "innovation", submitted_by_id: 1 }.to_json, headers: headers
      }.to_not change { CommercialValueTool::CashableSaving.count +
                         CommercialValueTool::NonCashableSaving.count +
                         CommercialValueTool::NonMonetisableSaving.count }

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq("not_found")
    end
  end
end
