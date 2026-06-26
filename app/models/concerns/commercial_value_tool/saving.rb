module CommercialValueTool
  # Shared behaviour for the three savings tables. Each saving belongs to a
  # contract row by +contract_record_id+ and carries the contract's OCID
  # redundantly so OCID-only queries do not require a join.
  module Saving
    extend ActiveSupport::Concern

    included do
      belongs_to :contract,
                 class_name: "CommercialValueTool::Contract",
                 foreign_key: :contract_record_id,
                 inverse_of: false,
                 optional: false

      scope :for_ocid, ->(ocid) { where(ocid: ocid) }
      scope :not_expired, -> { where("expired_record IS NOT TRUE") }
    end
  end
end
