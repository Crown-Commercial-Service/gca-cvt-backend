require 'rails_helper'

RSpec.describe Api::V1::ContractSerializer do
  let(:item) do
    CommercialValueTool::Contract::ContractData.new(
      record_id: 1, title: 'Payroll Services', ocid: 'ocds-abc-001',
      amount: BigDecimal('1000000.0'), start_date: Date.new(2025, 3, 1),
      end_date: Date.new(2026, 3, 1), calculation_completed: false
    )
  end

  let(:results) do
    CommercialValueTool::Contract::SearchResults.new(
      items: [ item ], current_page: 1, total_pages: 2, limit_value: 10,
      total_count: 11, sort_column: 'start_date', sort_direction: 'desc'
    )
  end

  subject(:output) { described_class.call(results) }

  it 'returns a hash with data and meta keys' do
    expect(output).to have_key(:data)
    expect(output).to have_key(:meta)
  end

  describe ':data' do
    it 'serializes each contract item' do
      expect(output[:data].length).to eq(1)
      contract = output[:data].first
      expect(contract[:record_id]).to eq(1)
      expect(contract[:title]).to eq('Payroll Services')
      expect(contract[:ocid]).to eq('ocds-abc-001')
      expect(contract[:status]).to eq('in_progress')
      expect(contract[:start_date]).to eq('2025-03-01')
      expect(contract[:end_date]).to eq('2026-03-01')
    end
  end

  describe ':meta' do
    it 'includes pagination and sort metadata' do
      meta = output[:meta]
      expect(meta[:page]).to eq(1)
      expect(meta[:total_pages]).to eq(2)
      expect(meta[:total_count]).to eq(11)
      expect(meta[:per_page]).to eq(10)
      expect(meta[:sort_column]).to eq('start_date')
      expect(meta[:sort_direction]).to eq('desc')
    end
  end
end
