module CommercialValueTool
  # Registry of the three savings types (cashable, non-cashable,
  # non-monetisable): their backing model, their permitted create/update
  # fields, and the slug-to-model resolution used across +CreateSaving+,
  # +DeleteSaving+ and +UpdateSavings+. Keeps that data in exactly one place.
  module SavingsType
    TYPES = {
      "cashable" => {
        model: CashableSaving,
        permitted_fields: %w[savings_type submitted_by_id cashable_savings baseline_approach baseline_value].freeze
      },
      "non-cashable" => {
        model: NonCashableSaving,
        permitted_fields: %w[savings_type submitted_by_id savings_value].freeze
      },
      "non-monetisable" => {
        model: NonMonetisableSaving,
        permitted_fields: %w[savings_type submitted_by_id].freeze
      }
    }.freeze

    # @return [Array<String>] the recognised type slugs
    def self.slugs = TYPES.keys

    # @param type [String] one of {slugs}
    # @return [Class] the matching savings model
    # @raise [CommercialValueTool::UnknownSavingsType] +type+ is not recognised
    def self.model_for(type) = fetch(type)[:model]

    # @param type [String] one of {slugs}
    # @return [Array<String>] fields permitted when creating/updating this type
    # @raise [CommercialValueTool::UnknownSavingsType] +type+ is not recognised
    def self.permitted_fields_for(type) = fetch(type)[:permitted_fields]

    # @param type [String] one of {slugs}
    # @return [String] the nested payload key used by +UpdateSavings+,
    #   e.g. "non-cashable" -> "non_cashable_savings"
    def self.payload_key_for(type) = "#{type.tr('-', '_')}_savings"

    def self.fetch(type)
      TYPES.fetch(type) { raise UnknownSavingsType, "Unknown savings type '#{type}'" }
    end
  end
end
