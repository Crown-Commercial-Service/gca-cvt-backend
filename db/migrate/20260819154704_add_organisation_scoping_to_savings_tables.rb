class AddOrganisationScopingToSavingsTables < ActiveRecord::Migration[8.1]
  def change
    %i[cashable_savings non_cashable_savings non_monetisable_savings].each do |table|
      add_column table, :represented_organisation_id, :string
      change_column table, :submitted_by_id, :string
    end
  end
end
