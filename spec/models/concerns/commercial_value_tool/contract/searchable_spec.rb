require 'rails_helper'

module CommercialValueTool
  RSpec.describe Contract::Searchable do
    let!(:payroll) do
      Contract.create!(
        record_id: 1, title: 'Payroll Services', ocid: 'ocds-abc-001',
        amount: 1_000_000, start_date: Date.new(2025, 3, 1), end_date: Date.new(2026, 3, 1),
        record_inserted_date: Time.zone.now
      )
    end

    let!(:it_services) do
      Contract.create!(
        record_id: 2, title: 'IT Managed Services', ocid: 'ocds-abc-002',
        amount: 500_000, start_date: Date.new(2024, 6, 1), end_date: Date.new(2025, 6, 1),
        record_inserted_date: Time.zone.now
      )
    end

    let!(:cleaning) do
      Contract.create!(
        record_id: 3, title: 'Cleaning Contract', ocid: 'ocds-abc-003',
        amount: 200_000, start_date: Date.new(2025, 9, 1), end_date: Date.new(2027, 9, 1),
        record_inserted_date: Time.zone.now
      )
    end

    describe '.search' do
      it 'returns a SearchResults struct' do
        result = Contract.search

        expect(result).to be_a(Contract::SearchResults)
      end

      it 'returns ContractData items, not ActiveRecord objects' do
        result = Contract.search

        result.each do |item|
          expect(item).to be_a(Contract::ContractData)
          expect(item).not_to respond_to(:save)
        end
      end

      it 'includes pagination metadata' do
        result = Contract.search

        expect(result.current_page).to eq(1)
        expect(result.total_pages).to be >= 1
        expect(result.limit_value).to eq(10)
        expect(result.total_count).to eq(3)
      end

      context 'with OCID deduplication' do
        let!(:payroll_old) do
          Contract.create!(
            record_id: 4, title: 'Payroll Services (Old)', ocid: 'ocds-abc-001',
            amount: 800_000, start_date: Date.new(2024, 1, 1), end_date: Date.new(2025, 1, 1),
            record_inserted_date: 1.day.ago
          )
        end

        it 'returns only the most recent record per OCID' do
          result = Contract.search
          ocids = result.map(&:ocid)

          expect(ocids).to include('ocds-abc-001')
          expect(result.items.count { |c| c.ocid == 'ocds-abc-001' }).to eq(1)

          matching = result.items.find { |c| c.ocid == 'ocds-abc-001' }
          expect(matching.title).to eq('Payroll Services')
        end
      end

      context 'with calculation_completed' do
        it 'returns false when calculation has not been completed' do
          result = Contract.search
          item = result.items.find { |c| c.ocid == 'ocds-abc-001' }

          expect(item.calculation_completed).to be false
        end

        it 'returns true when calculation has been completed' do
          payroll.update!(calculation_completed: true)

          result = Contract.search
          item = result.items.find { |c| c.ocid == 'ocds-abc-001' }

          expect(item.calculation_completed).to be true
        end
      end

      context 'with search' do
        it 'filters by title (case-insensitive)' do
          result = Contract.search(search: 'payroll')

          expect(result.items.map(&:title)).to contain_exactly('Payroll Services')
        end

        it 'filters by OCID' do
          result = Contract.search(search: 'ocds-abc-002')

          expect(result.items.map(&:title)).to contain_exactly('IT Managed Services')
        end

        it 'returns no results when search does not match' do
          result = Contract.search(search: 'nonexistent-xyz')

          expect(result.items).to be_empty
        end
      end

      context 'with sorting' do
        it 'defaults to start_date descending' do
          result = Contract.search

          expect(result.sort_column).to eq('start_date')
          expect(result.sort_direction).to eq('desc')
          expect(result.items.map(&:title)).to eq([ 'Cleaning Contract', 'Payroll Services', 'IT Managed Services' ])
        end

        it 'sorts by title ascending' do
          result = Contract.search(sort: 'title', direction: 'asc')

          expect(result.sort_column).to eq('title')
          expect(result.sort_direction).to eq('asc')
          expect(result.items.map(&:title)).to eq([ 'Cleaning Contract', 'IT Managed Services', 'Payroll Services' ])
        end

        it 'sorts by amount descending' do
          result = Contract.search(sort: 'amount', direction: 'desc')

          expect(result.items.map(&:amount)).to eq([ 1_000_000, 500_000, 200_000 ])
        end

        it 'falls back to defaults for invalid sort params' do
          result = Contract.search(sort: 'invalid', direction: 'sideways')

          expect(result.sort_column).to eq('start_date')
          expect(result.sort_direction).to eq('desc')
        end

        context 'with status sorting' do
          before { payroll.update!(calculation_completed: true) }

          it 'sorts completed before in_progress when ascending' do
            result = Contract.search(sort: 'status', direction: 'asc')

            statuses = result.items.map(&:status)
            completed_index = statuses.index('completed')
            in_progress_index = statuses.index('in_progress')

            expect(completed_index).to be < in_progress_index
          end

          it 'sorts in_progress before completed when descending' do
            result = Contract.search(sort: 'status', direction: 'desc')

            statuses = result.items.map(&:status)
            in_progress_index = statuses.index('in_progress')
            completed_index = statuses.index('completed')

            expect(in_progress_index).to be < completed_index
          end
        end
      end

      context 'with date filters' do
        it 'filters by start_date_from' do
          result = Contract.search(filters: { start_date_from: Date.new(2025, 1, 1) })

          expect(result.items.map(&:title)).to contain_exactly('Payroll Services', 'Cleaning Contract')
        end

        it 'filters by start_date_to' do
          result = Contract.search(filters: { start_date_to: Date.new(2024, 12, 31) })

          expect(result.items.map(&:title)).to contain_exactly('IT Managed Services')
        end

        it 'filters by end_date_from' do
          result = Contract.search(filters: { end_date_from: Date.new(2026, 1, 1) })

          expect(result.items.map(&:title)).to contain_exactly('Payroll Services', 'Cleaning Contract')
        end

        it 'filters by end_date_to' do
          result = Contract.search(filters: { end_date_to: Date.new(2025, 12, 31) })

          expect(result.items.map(&:title)).to contain_exactly('IT Managed Services')
        end
      end

      context 'with value filters' do
        it 'filters by value_min' do
          result = Contract.search(filters: { value_min: '600000' })

          expect(result.items.map(&:title)).to contain_exactly('Payroll Services')
        end

        it 'filters by value_max' do
          result = Contract.search(filters: { value_max: '300000' })

          expect(result.items.map(&:title)).to contain_exactly('Cleaning Contract')
        end

        it 'combines value_min and value_max' do
          result = Contract.search(filters: { value_min: '300000', value_max: '800000' })

          expect(result.items.map(&:title)).to contain_exactly('IT Managed Services')
        end
      end

      context 'with status filter' do
        before { payroll.update!(calculation_completed: true) }

        it 'filters to completed contracts' do
          result = Contract.search(filters: { status: 'completed' })

          expect(result.items.map(&:title)).to contain_exactly('Payroll Services')
        end

        it 'filters to in_progress contracts' do
          result = Contract.search(filters: { status: 'in_progress' })

          expect(result.items.map(&:title)).to contain_exactly('IT Managed Services', 'Cleaning Contract')
        end

        it 'ignores unknown status values' do
          result = Contract.search(filters: { status: 'bogus' })

          expect(result.items.map(&:title)).to contain_exactly(
            'Payroll Services', 'IT Managed Services', 'Cleaning Contract'
          )
        end

        it 'combines with other filters' do
          result = Contract.search(filters: { status: 'in_progress', value_min: '300000' })

          expect(result.items.map(&:title)).to contain_exactly('IT Managed Services')
        end
      end

      context 'with pagination' do
        before do
          11.times do |i|
            Contract.create!(
              record_id: 100 + i, title: "Bulk Contract #{i}", ocid: "ocds-bulk-#{format('%03d', i)}",
              amount: 100_000, start_date: Date.new(2025, 1, 1) + i.days, end_date: Date.new(2026, 1, 1),
              record_inserted_date: Time.zone.now
            )
          end
        end

        it 'returns the first page with up to 10 results' do
          result = Contract.search(page: 1)

          expect(result.items.length).to eq(10)
          expect(result.current_page).to eq(1)
          expect(result.total_pages).to eq(2)
          expect(result.total_count).to eq(14)
        end

        it 'returns the second page with remaining results' do
          result = Contract.search(page: 2)

          expect(result.items.length).to eq(4)
          expect(result.current_page).to eq(2)
        end
      end

      context 'with combined search, filter, and sort' do
        it 'applies all criteria together' do
          result = Contract.search(
            search: 'Services',
            sort: 'amount',
            direction: 'asc',
            filters: { value_min: '400000' }
          )

          expect(result.items.map(&:title)).to eq([ 'IT Managed Services', 'Payroll Services' ])
        end
      end
    end

    describe 'SearchResults' do
      let(:items) { [ Contract::ContractData.new(record_id: 1, title: 'Test', ocid: 'ocds-001', amount: 100, start_date: Date.today, end_date: Date.today) ] }
      let(:results) { Contract::SearchResults.new(items: items, current_page: 1, total_pages: 1, limit_value: 10, total_count: 1, sort_column: 'title', sort_direction: 'asc') }

      it 'is enumerable' do
        expect(results).to be_a(Enumerable)
        expect(results.map(&:title)).to eq([ 'Test' ])
      end

      it 'exposes pagination attributes' do
        expect(results.current_page).to eq(1)
        expect(results.total_pages).to eq(1)
        expect(results.limit_value).to eq(10)
        expect(results.total_count).to eq(1)
      end

      it 'exposes sort attributes' do
        expect(results.sort_column).to eq('title')
        expect(results.sort_direction).to eq('asc')
      end
    end

    describe 'ContractData' do
      let(:data) { Contract::ContractData.new(record_id: 1, title: 'Test', ocid: 'ocds-001', amount: 500_000, start_date: Date.new(2025, 1, 1), end_date: Date.new(2026, 1, 1), calculation_completed: false) }

      it 'exposes all contract fields' do
        expect(data.record_id).to eq(1)
        expect(data.title).to eq('Test')
        expect(data.ocid).to eq('ocds-001')
        expect(data.amount).to eq(500_000)
        expect(data.start_date).to eq(Date.new(2025, 1, 1))
        expect(data.end_date).to eq(Date.new(2026, 1, 1))
      end

      it 'does not respond to ActiveRecord methods' do
        expect(data).not_to respond_to(:save)
        expect(data).not_to respond_to(:update)
        expect(data).not_to respond_to(:destroy)
      end

      it 'returns completed status when calculation_completed is true' do
        completed_data = Contract::ContractData.new(record_id: 1, title: 'Test', ocid: 'ocds-001', amount: 100, start_date: Date.today, end_date: Date.today, calculation_completed: true)

        expect(completed_data.status).to eq('completed')
      end

      it 'returns in_progress status when calculation_completed is false' do
        expect(data.status).to eq('in_progress')
      end

      it 'derives status from STATUS_MAP' do
        Contract::STATUS_MAP.each do |bool_value, expected_status|
          item = Contract::ContractData.new(record_id: 1, title: 'T', ocid: 'o', amount: 0, start_date: Date.today, end_date: Date.today, calculation_completed: bool_value)

          expect(item.status).to eq(expected_status)
        end
      end
    end
  end
end
