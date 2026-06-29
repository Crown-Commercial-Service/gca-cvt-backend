require 'rails_helper'

RSpec.describe 'GET /api/v1/savings/:ocid' do
  let(:ocid) { 'ocds-test-savings-001' }
  let!(:contract) do
    create(:contract,
           record_id: 200_001,
           ocid: ocid,
           title: 'Savings Endpoint Test Contract',
           amount: 200_000,
           calculation_completed: true)
  end

  context 'when the contract has savings of all three types' do
    let!(:cashable) { create(:cashable_saving, contract: contract, baseline_value: 240_000, savings_type: 'contract_recompete') }
    let!(:non_cashable_old) { create(:non_cashable_saving, contract: contract, savings_value: 1_000, updated_at: 3.days.ago) }
    let!(:non_cashable_new) { create(:non_cashable_saving, contract: contract, savings_value: 2_000, updated_at: 1.hour.ago) }
    let!(:non_monetisable_old) { create(:non_monetisable_saving, contract: contract, savings_type: 'innovation', updated_at: 2.days.ago) }
    let!(:non_monetisable_new) { create(:non_monetisable_saving, contract: contract, savings_type: 'sustainability', updated_at: 1.hour.ago) }

    before { get "/api/v1/savings/#{ocid}" }

    it 'returns 200 with the full payload' do
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data]).to include(:contract, :cashable_savings, :non_cashable_savings, :non_monetisable_savings)
    end

    it 'serialises contract including calculation_completed' do
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:contract]).to include(
        record_id: 200_001,
        ocid: ocid,
        title: 'Savings Endpoint Test Contract',
        amount: '200000.0',
        calculation_completed: true
      )
    end

    it 'returns the cashable saving' do
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:cashable_savings]).to contain_exactly(
        a_hash_including(
          id: cashable.id,
          ocid: ocid,
          savings_type: 'contract_recompete',
          baseline_value: '240000.0',
          cashable_savings: true
        )
      )
    end

    it 'orders non-cashable savings newest first' do
      body = JSON.parse(response.body, symbolize_names: true)
      ids = body[:data][:non_cashable_savings].map { |s| s[:id] }
      expect(ids).to eq([ non_cashable_new.id, non_cashable_old.id ])
    end

    it 'orders non-monetisable savings newest first' do
      body = JSON.parse(response.body, symbolize_names: true)
      types = body[:data][:non_monetisable_savings].map { |s| s[:savings_type] }
      expect(types).to eq([ 'sustainability', 'innovation' ])
    end
  end

  context 'when the contract exists but has no savings' do
    it 'returns 200 with empty savings arrays' do
      get "/api/v1/savings/#{ocid}"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:contract][:record_id]).to eq(200_001)
      expect(body[:data][:cashable_savings]).to eq([])
      expect(body[:data][:non_cashable_savings]).to eq([])
      expect(body[:data][:non_monetisable_savings]).to eq([])
    end
  end

  context 'when the contract does not exist' do
    it 'returns 404 with an error payload' do
      get '/api/v1/savings/ocds-does-not-exist'

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq('not_found')
      expect(body[:error][:message]).to include('ocds-does-not-exist')
    end
  end

  context 'when several contract rows share the OCID' do
    let!(:newer_contract) do
      create(:contract,
             record_id: 200_002,
             ocid: ocid,
             title: 'Newer Version',
             amount: 180_000,
             calculation_completed: false,
             record_inserted_date: 1.hour.from_now)
    end

    it 'returns the most recently inserted record only' do
      get "/api/v1/savings/#{ocid}"

      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:contract][:record_id]).to eq(200_002)
      expect(body[:data][:contract][:title]).to eq('Newer Version')
    end
  end

  context 'when a saving is expired' do
    let!(:active) { create(:cashable_saving, contract: contract, savings_type: 'contract_recompete') }
    let!(:expired) { create(:cashable_saving, contract: contract, savings_type: 'volume_reduction', expired_record: true) }

    it 'excludes expired records' do
      get "/api/v1/savings/#{ocid}"

      body = JSON.parse(response.body, symbolize_names: true)
      types = body[:data][:cashable_savings].map { |s| s[:savings_type] }
      expect(types).to contain_exactly('contract_recompete')
    end
  end
end
