FactoryBot.define do
  factory :non_cashable_saving, class: 'CommercialValueTool::NonCashableSaving' do
    association :contract, factory: :contract
    ocid { contract.ocid }
    contract_record_id { contract.record_id }
    savings_type { 'social_value' }
    savings_value { 5_000 }
    submitted_by_id { 1 }
    expired_record { false }
  end
end
