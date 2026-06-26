module CommercialValueTool
  # Represents a contract record sourced from the contracts database.
  #
  # Uses DISTINCT ON (ocid) to surface only the latest version of
  # each contract, and supports searching, sorting, filtering by
  # date range and value range, and Kaminari pagination.
  class Contract < ApplicationRecord
    include Searchable

    self.table_name = "contracts"
    self.primary_key = :record_id

    # @param ocid [String]
    # @return [Contract, nil] the most recently inserted contract row for the OCID
    def self.latest_for_ocid(ocid)
      where(ocid: ocid).order(record_inserted_date: :desc).first
    end
  end
end
