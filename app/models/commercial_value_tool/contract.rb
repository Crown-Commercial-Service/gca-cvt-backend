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
  end
end
