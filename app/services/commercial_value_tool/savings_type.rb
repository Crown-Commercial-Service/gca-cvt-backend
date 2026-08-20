module CommercialValueTool
  # Registry of the three savings types (cashable, non-cashable,
  # non-monetisable): their backing model, their permitted create/update
  # fields, and the slug-to-model resolution used across +CreateSaving+,
  # +DeleteSaving+ and +UpdateSavings+. Keeps that data in exactly one place.
  module SavingsType
    TYPES = {
      "cashable" => {
        model: CashableSaving,
        payload_key: "cashable_savings",
        permitted_fields: %w[savings_type cashable_savings baseline_approach baseline_value].freeze
      },
      "non-cashable" => {
        model: NonCashableSaving,
        payload_key: "non_cashable_savings",
        permitted_fields: %w[savings_type savings_value].freeze
      },
      "non-monetisable" => {
        model: NonMonetisableSaving,
        payload_key: "non_monetisable_savings",
        permitted_fields: %w[savings_type].freeze
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
    # @raise [CommercialValueTool::UnknownSavingsType] +type+ is not recognised
    def self.payload_key_for(type) = fetch(type)[:payload_key]

    # @return [Hash{Symbol => Array<Symbol>}] the full nested strong-parameters
    #   whitelist for +PUT /api/v1/savings/:ocid+, keyed by payload key, e.g.
    #   { cashable_savings: [ :savings_id, :savings_type, ... ], ... }
    def self.permitted_update_params
      TYPES.values.to_h do |config|
        [ config[:payload_key].to_sym, [ :savings_id, *config[:permitted_fields].map(&:to_sym) ] ]
      end
    end

    def self.fetch(type)
      TYPES.fetch(type) { raise UnknownSavingsType, "Unknown savings type '#{type}'" }
    end
  end
end
