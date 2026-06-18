require 'rails_helper'

module CommercialValueTool
  RSpec.describe Contract, type: :model do
    it 'uses the contracts table' do
      expect(described_class.table_name).to eq('contracts')
    end

    it 'uses record_id as the primary key' do
      expect(described_class.primary_key).to eq('record_id')
    end

    it 'includes Searchable' do
      expect(described_class.ancestors).to include(Contract::Searchable)
    end
  end
end
