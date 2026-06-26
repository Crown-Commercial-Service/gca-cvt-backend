module CommercialValueTool
  # Represents a non-monetisable savings record submitted through the journey.
  class NonMonetisableSaving < ApplicationRecord
    include Saving

    self.table_name = "non_monetisable_savings"
  end
end
