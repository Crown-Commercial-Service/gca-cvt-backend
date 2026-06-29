# Seeds a small set of non-cashable savings spread across the synthetic
# peer contracts so the /api/v1/savings/:ocid endpoint returns
# multi-record arrays for testing the latest-first ordering.

savings_rows = [
  { ocid: 'ocds-b5fd17-c1a2b3c4-9014-4000-a000-000000009014', contract_record_id: 136_744_022, savings_type: 'social_value',         savings_value:  12_500 },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9014-4000-a000-000000009014', contract_record_id: 136_744_022, savings_type: 'risk_avoidance',       savings_value:   8_000 },
  { ocid: 'ocds-b5fd17-c1a2b3c4-1111-4000-a000-000000000001', contract_record_id: 136_744_001, savings_type: 'efficiency_gain',      savings_value:   4_750 },
  { ocid: 'ocds-b5fd17-c1a2b3c4-5555-4000-a000-000000000005', contract_record_id: 136_744_005, savings_type: 'risk_avoidance',       savings_value:   6_200 },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9009-4000-a000-000000009009', contract_record_id: 136_744_017, savings_type: 'social_value',         savings_value:  15_000 }
].freeze

synthetic_ocids = savings_rows.map { |r| r[:ocid] }.uniq
CommercialValueTool::NonCashableSaving.where(ocid: synthetic_ocids, expired_record: false).delete_all

savings_rows.each do |row|
  CommercialValueTool::NonCashableSaving.create!(
    ocid:               row[:ocid],
    contract_record_id: row[:contract_record_id],
    savings_type:       row[:savings_type],
    savings_value:      row[:savings_value],
    expired_record:     false,
    submitted_by_id:    1
  )
end

puts "Seeded #{savings_rows.size} non-cashable savings"
