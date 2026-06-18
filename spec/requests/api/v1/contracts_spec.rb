require 'rails_helper'

RSpec.describe 'GET /api/v1/contracts' do
  let!(:payroll) do
    create(:contract, title: 'Payroll Services', ocid: 'ocds-abc-001',
           amount: 1_000_000, start_date: Date.new(2025, 3, 1),
           end_date: Date.new(2026, 3, 1), calculation_completed: true)
  end

  let!(:it_services) do
    create(:contract, title: 'IT Managed Services', ocid: 'ocds-abc-002',
           amount: 500_000, start_date: Date.new(2024, 6, 1),
           end_date: Date.new(2025, 6, 1))
  end

  it 'returns 200 with data and meta' do
    get '/api/v1/contracts'

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body, symbolize_names: true)
    expect(body).to have_key(:data)
    expect(body).to have_key(:meta)
  end

  it 'serializes contract fields' do
    get '/api/v1/contracts'

    body = JSON.parse(response.body, symbolize_names: true)
    titles = body[:data].map { |c| c[:title] }
    expect(titles).to include('Payroll Services', 'IT Managed Services')
  end

  it 'filters by search term' do
    get '/api/v1/contracts', params: { search: 'payroll' }

    body = JSON.parse(response.body, symbolize_names: true)
    expect(body[:data].map { |c| c[:title] }).to contain_exactly('Payroll Services')
  end

  it 'sorts by a given column and direction' do
    get '/api/v1/contracts', params: { sort: 'amount', direction: 'asc' }

    body = JSON.parse(response.body, symbolize_names: true)
    amounts = body[:data].map { |c| c[:amount].to_f }
    expect(amounts).to eq(amounts.sort)
  end

  it 'filters by status' do
    get '/api/v1/contracts', params: { status: 'completed' }

    body = JSON.parse(response.body, symbolize_names: true)
    expect(body[:data].map { |c| c[:title] }).to contain_exactly('Payroll Services')
  end

  it 'includes correct meta' do
    get '/api/v1/contracts'

    meta = JSON.parse(response.body, symbolize_names: true)[:meta]
    expect(meta[:page]).to eq(1)
    expect(meta[:sort_column]).to eq('start_date')
    expect(meta[:sort_direction]).to eq('desc')
  end

  it 'paginates results' do
    12.times { |i| create(:contract, ocid: "ocds-bulk-#{i}") }

    get '/api/v1/contracts', params: { page: 2 }

    body = JSON.parse(response.body, symbolize_names: true)
    expect(body[:meta][:page]).to eq(2)
  end
end
