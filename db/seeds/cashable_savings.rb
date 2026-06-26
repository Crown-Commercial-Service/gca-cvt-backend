# Seed cashable savings for the synthetic peer contracts. Mirrors the
# frontend seed (commercial-value-tool db/seeds/cashable_savings.rb) so
# the consolidated /api/v1/savings/:ocid endpoint returns meaningful
# data for testing. submitted_by_id is a fixed integer here because the
# backend has no users table — it stores the value as opaque data.

# Ensure contracts exist before creating savings (cashable_savings.rb sorts
# before contracts.rb so seeds.rb would otherwise load it first).
load File.join(__dir__, 'contracts.rb')

savings_rows = [
  # previous_cost
  { ocid: 'ocds-b5fd17-c1a2b3c4-1111-4000-a000-000000000001', contract_record_id: 136_744_001, baseline_approach: 'previous_cost',        baseline_value: 220_400, savings_type: 'contract_recompete' },
  { ocid: 'ocds-b5fd17-c1a2b3c4-3333-4000-a000-000000000003', contract_record_id: 136_744_003, baseline_approach: 'previous_cost',        baseline_value: 228_000, savings_type: 'volume_reduction'   },
  { ocid: 'ocds-b5fd17-c1a2b3c4-7777-4000-a000-000000000007', contract_record_id: 136_744_007, baseline_approach: 'previous_cost',        baseline_value: 243_400, savings_type: 'de_scoping'         },
  # budget
  { ocid: 'ocds-b5fd17-c1a2b3c4-2222-4000-a000-000000000002', contract_record_id: 136_744_002, baseline_approach: 'budget',               baseline_value: 218_400, savings_type: 'contract_recompete' },
  { ocid: 'ocds-b5fd17-c1a2b3c4-4444-4000-a000-000000000004', contract_record_id: 136_744_004, baseline_approach: 'budget',               baseline_value: 225_600, savings_type: 'volume_reduction'   },
  { ocid: 'ocds-b5fd17-c1a2b3c4-8888-4000-a000-000000000008', contract_record_id: 136_744_008, baseline_approach: 'budget',               baseline_value: 241_200, savings_type: 'de_scoping'         },
  # external_benchmark
  { ocid: 'ocds-b5fd17-c1a2b3c4-5555-4000-a000-000000000005', contract_record_id: 136_744_005, baseline_approach: 'external_benchmark',   baseline_value: 226_000, savings_type: 'contract_recompete' },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9001-4000-a000-000000009001', contract_record_id: 136_744_009, baseline_approach: 'external_benchmark',   baseline_value: 232_600, savings_type: 'volume_reduction'   },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9002-4000-a000-000000009002', contract_record_id: 136_744_010, baseline_approach: 'external_benchmark',   baseline_value: 253_000, savings_type: 'de_scoping'         },
  # market_intelligence
  { ocid: 'ocds-b5fd17-c1a2b3c4-9003-4000-a000-000000009003', contract_record_id: 136_744_011, baseline_approach: 'market_intelligence',  baseline_value: 214_400, savings_type: 'contract_recompete' },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9004-4000-a000-000000009004', contract_record_id: 136_744_012, baseline_approach: 'market_intelligence',  baseline_value: 220_200, savings_type: 'volume_reduction'   },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9005-4000-a000-000000009005', contract_record_id: 136_744_013, baseline_approach: 'market_intelligence',  baseline_value: 233_800, savings_type: 'de_scoping'         },
  # median_bid
  { ocid: 'ocds-b5fd17-c1a2b3c4-9006-4000-a000-000000009006', contract_record_id: 136_744_014, baseline_approach: 'median_bid',           baseline_value: 212_600, savings_type: 'contract_recompete' },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9007-4000-a000-000000009007', contract_record_id: 136_744_015, baseline_approach: 'median_bid',           baseline_value: 217_800, savings_type: 'volume_reduction'   },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9008-4000-a000-000000009008', contract_record_id: 136_744_016, baseline_approach: 'median_bid',           baseline_value: 227_800, savings_type: 'de_scoping'         },
  # should_cost_exercise
  { ocid: 'ocds-b5fd17-c1a2b3c4-9009-4000-a000-000000009009', contract_record_id: 136_744_017, baseline_approach: 'should_cost_exercise', baseline_value: 228_400, savings_type: 'contract_recompete' },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9010-4000-a000-000000009010', contract_record_id: 136_744_018, baseline_approach: 'should_cost_exercise', baseline_value: 239_000, savings_type: 'volume_reduction'   },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9011-4000-a000-000000009011', contract_record_id: 136_744_019, baseline_approach: 'should_cost_exercise', baseline_value: 263_400, savings_type: 'de_scoping'         },
  # other
  { ocid: 'ocds-b5fd17-c1a2b3c4-9012-4000-a000-000000009012', contract_record_id: 136_744_020, baseline_approach: 'other',                baseline_value: 208_000, savings_type: 'contract_recompete' },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9013-4000-a000-000000009013', contract_record_id: 136_744_021, baseline_approach: 'other',                baseline_value: 212_200, savings_type: 'volume_reduction'   },
  { ocid: 'ocds-b5fd17-c1a2b3c4-9014-4000-a000-000000009014', contract_record_id: 136_744_022, baseline_approach: 'other',                baseline_value: 223_000, savings_type: 'de_scoping'         }
].freeze

synthetic_ocids = savings_rows.map { |r| r[:ocid] }
CommercialValueTool::CashableSaving.where(ocid: synthetic_ocids, expired_record: false).delete_all

savings_rows.each do |row|
  CommercialValueTool::CashableSaving.create!(
    ocid:               row[:ocid],
    contract_record_id: row[:contract_record_id],
    baseline_approach:  row[:baseline_approach],
    baseline_value:     row[:baseline_value],
    cashable_savings:   true,
    savings_type:       row[:savings_type],
    expired_record:     false,
    submitted_by_id:    1
  )
end

puts "Seeded #{savings_rows.size} cashable savings"
