FactoryBot.define do
  factory :cashable_saving, class: 'CommercialValueTool::CashableSaving' do
    association :contract, factory: :contract
    ocid { contract.ocid }
    contract_record_id { contract.record_id }
    cashable_savings { true }
    savings_type { 'contract_recompete' }
    baseline_approach { 'previous_cost' }
    baseline_value { 220_000 }
    submitted_by_id { 1 }
    expired_record { false }
  end
end
