module CommercialValueTool
  # Raised when a savings `type` slug does not match a known savings type
  # (cashable, non-cashable, non-monetisable).
  class UnknownSavingsType < StandardError; end
end
