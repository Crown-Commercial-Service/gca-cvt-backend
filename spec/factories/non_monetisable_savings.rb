FactoryBot.define do
  factory :non_monetisable_saving, class: 'CommercialValueTool::NonMonetisableSaving' do
    association :contract, factory: :contract
    ocid { contract.ocid }
    contract_record_id { contract.record_id }
    savings_type { 'innovation' }
    submitted_by_id { 1 }
    expired_record { false }
  end
end
