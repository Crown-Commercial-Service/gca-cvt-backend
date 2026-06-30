require "rails_helper"

RSpec.describe "DELETE /api/v1/savings/:type/:savings_id" do
  let!(:contract) { create(:contract) }

  shared_examples "a soft-delete endpoint" do |type:, factory:, model:|
    let!(:saving) { create(factory, contract: contract) }
    let!(:other_saving) { create(factory, contract: contract) }

    it "returns 204 No Content" do
      delete "/api/v1/savings/#{type}/#{saving.id}"

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it "marks the targeted record as expired" do
      delete "/api/v1/savings/#{type}/#{saving.id}"

      expect(model.find(saving.id).expired_record).to be(true)
    end

    it "leaves other records of the same type untouched" do
      delete "/api/v1/savings/#{type}/#{saving.id}"

      expect(model.find(other_saving.id).expired_record).to be(false)
    end

    it "leaves records of other savings types untouched" do
      cashable = create(:cashable_saving, contract: contract)
      non_cashable = create(:non_cashable_saving, contract: contract)
      non_monetisable = create(:non_monetisable_saving, contract: contract)

      delete "/api/v1/savings/#{type}/#{saving.id}"

      expect(CommercialValueTool::CashableSaving.find(cashable.id).expired_record).to be(false)
      expect(CommercialValueTool::NonCashableSaving.find(non_cashable.id).expired_record).to be(false)
      expect(CommercialValueTool::NonMonetisableSaving.find(non_monetisable.id).expired_record).to be(false)
    end
  end

  context "when the type is cashable" do
    it_behaves_like "a soft-delete endpoint",
                    type: "cashable",
                    factory: :cashable_saving,
                    model: CommercialValueTool::CashableSaving
  end

  context "when the type is non-cashable" do
    it_behaves_like "a soft-delete endpoint",
                    type: "non-cashable",
                    factory: :non_cashable_saving,
                    model: CommercialValueTool::NonCashableSaving
  end

  context "when the type is non-monetisable" do
    it_behaves_like "a soft-delete endpoint",
                    type: "non-monetisable",
                    factory: :non_monetisable_saving,
                    model: CommercialValueTool::NonMonetisableSaving
  end

  context "when no record exists for the given savings_id and type" do
    it "returns 404 with a not_found error" do
      delete "/api/v1/savings/cashable/999999999"

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq("not_found")
    end
  end

  context "when the record exists but in a different savings type" do
    let!(:cashable) { create(:cashable_saving, contract: contract) }

    it "returns 404 (does not cross-match across types)" do
      delete "/api/v1/savings/non-cashable/#{cashable.id}"

      expect(response).to have_http_status(:not_found)
    end

    it "leaves the original record untouched" do
      delete "/api/v1/savings/non-cashable/#{cashable.id}"

      expect(CommercialValueTool::CashableSaving.find(cashable.id).expired_record).to be(false)
    end
  end

  context "when the record has already been soft-deleted" do
    let!(:cashable) { create(:cashable_saving, contract: contract, expired_record: true) }

    it "returns 404 because the record is no longer active" do
      delete "/api/v1/savings/cashable/#{cashable.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the type is invalid" do
    it "is rejected by the route constraint with 404" do
      delete "/api/v1/savings/bogus-type/1"

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when the savings_id is non-numeric" do
    it "is rejected by the route constraint with 404" do
      delete "/api/v1/savings/cashable/not-a-number"

      expect(response).to have_http_status(:not_found)
    end
  end
end
