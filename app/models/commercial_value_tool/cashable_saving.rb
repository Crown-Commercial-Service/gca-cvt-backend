module CommercialValueTool
  # Represents a cashable savings record submitted through the journey.
  class CashableSaving < ApplicationRecord
    include Saving

    self.table_name = "cashable_savings"
  end
end
