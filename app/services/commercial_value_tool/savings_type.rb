module CommercialValueTool
  # Resolves a savings `type` slug to its backing model class. Shared by
  # +CreateSaving+ and +DeleteSaving+ so the type-to-model mapping and its
  # unknown-type handling live in exactly one place.
  module SavingsType
    MODELS = {
      "cashable" => CashableSaving,
      "non-cashable" => NonCashableSaving,
      "non-monetisable" => NonMonetisableSaving
    }.freeze

    # @param type [String] one of the keys in {MODELS}
    # @return [Class] the matching savings model
    # @raise [CommercialValueTool::UnknownSavingsType] +type+ is not recognised
    def self.model_for(type)
      MODELS.fetch(type) { raise UnknownSavingsType, "Unknown savings type '#{type}'" }
    end
  end
end
