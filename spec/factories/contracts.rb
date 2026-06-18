FactoryBot.define do
  factory :contract, class: 'CommercialValueTool::Contract' do
    sequence(:ocid) { |n| "ocds-contract-#{n}" }
    sequence(:tender_id) { |n| "tender-#{n}" }
    sequence(:record_inserted_date) { |n| n.seconds.ago }
    organisation_id { 'org-1' }
    organisation_name { 'Test Organisation' }
    amount { 200_000 }
    start_date { 1.year.ago }
    end_date { 1.year.from_now }
    title { 'Test Contract' }
    cpv_code { '72000000' }
    calculation_completed { false }
    expired_record { false }

    trait :completed do
      calculation_completed { true }
    end
  end
end
