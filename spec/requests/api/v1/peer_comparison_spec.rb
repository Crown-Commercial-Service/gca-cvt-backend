require 'rails_helper'

RSpec.describe 'GET /api/v1/savings/:ocid/peer-comparison' do
  context 'when the contract exists with peers across multiple baseline approaches' do
    let!(:target) { create(:contract, :completed, amount: 100_000) }
    let!(:target_saving) do
      create(:cashable_saving, contract: target, baseline_approach: 'previous_cost', baseline_value: 150_000)
    end
    let!(:peer_one) { create(:contract, :completed, amount: 100_000) }
    let!(:peer_two) { create(:contract, :completed, amount: 100_000) }

    before do
      create(:cashable_saving, contract: peer_one, baseline_approach: 'previous_cost', baseline_value: 120_000)
      create(:cashable_saving, contract: peer_two, baseline_approach: 'market_pricing', baseline_value: 130_000)

      get "/api/v1/savings/#{target.ocid}/peer-comparison"
    end

    it 'returns 200 with a full payload' do
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data]).to include(
        :contract_approach, :contract_percentage, :contract_absolute_value,
        :available_approaches, :peer_group_averages
      )
    end

    it "returns the contract's own approach and percentage" do
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:contract_approach]).to eq('previous_cost')
      expect(body[:data][:available_approaches]).to include('previous_cost')
    end

    it 'includes peer averages for multiple approaches' do
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:available_approaches]).to contain_exactly('previous_cost', 'market_pricing')
      expect(body[:data][:peer_group_averages].keys).to contain_exactly(:previous_cost, :market_pricing)
    end

    it 'serialises money fields as strings and percentage fields as numbers' do
      body = JSON.parse(response.body)
      data = body['data']

      expect(data['contract_absolute_value']).to be_a(String)
      expect(data['contract_percentage']).to be_a(Numeric)

      average = data['peer_group_averages']['previous_cost']
      expect(average['absolute_mean']).to be_a(String)
      expect(average['absolute_median']).to be_a(String)
      expect(average['mean']).to be_a(Numeric)
      expect(average['median']).to be_a(Numeric)
    end

    it 'does not include a peer_group_name key' do
      body = JSON.parse(response.body)
      expect(body['data']).not_to have_key('peer_group_name')
    end
  end

  context 'when the contract has no peers' do
    let!(:target) { create(:contract, :completed, amount: 100_000) }

    before { get "/api/v1/savings/#{target.ocid}/peer-comparison" }

    it 'returns 200 with empty peer_group_averages and available_approaches' do
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:peer_group_averages]).to eq({})
      expect(body[:data][:available_approaches]).to eq([])
    end
  end

  context 'when the contract has no cashable saving of its own' do
    let!(:target) { create(:contract, :completed, amount: 100_000) }
    let!(:peer) { create(:contract, :completed, amount: 100_000) }

    before do
      create(:cashable_saving, contract: peer, baseline_approach: 'previous_cost', baseline_value: 120_000)
      get "/api/v1/savings/#{target.ocid}/peer-comparison"
    end

    it "returns null for the contract's own fields but still populates peer_group_averages" do
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:data][:contract_approach]).to be_nil
      expect(body[:data][:contract_percentage]).to be_nil
      expect(body[:data][:contract_absolute_value]).to be_nil
      expect(body[:data][:peer_group_averages]).not_to eq({})
    end
  end

  context 'when the contract does not exist' do
    it 'returns 404 with an error payload' do
      get '/api/v1/savings/ocds-does-not-exist/peer-comparison'

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq('not_found')
      expect(body[:error][:message]).to include('ocds-does-not-exist')
    end
  end
end
