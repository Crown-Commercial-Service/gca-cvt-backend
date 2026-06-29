module CommercialValueTool
  # Represents a non-cashable savings record submitted through the journey.
  class NonCashableSaving < ApplicationRecord
    include Saving

    self.table_name = "non_cashable_savings"
  end
end
