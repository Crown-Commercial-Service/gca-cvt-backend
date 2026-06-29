class CreateSavingsTables < ActiveRecord::Migration[8.1]
  def change
    create_table :cashable_savings do |t|
      t.boolean :expired_record
      t.datetime :expired_date_time
      t.string :ocid
      t.boolean :cashable_savings
      t.string :savings_type
      t.string :baseline_approach
      t.decimal :baseline_value, precision: 15, scale: 2
      t.bigint :submitted_by_id
      t.bigint :contract_record_id, null: false

      t.timestamps

      t.index :ocid
      t.index :expired_record
      t.index :submitted_by_id
    end
    add_foreign_key :cashable_savings, :contracts, column: 'contract_record_id', primary_key: 'record_id'

    create_table :non_cashable_savings do |t|
      t.boolean :expired_record
      t.datetime :expired_date_time
      t.string :ocid
      t.string :savings_type
      t.decimal :savings_value, precision: 15, scale: 2
      t.bigint :submitted_by_id
      t.bigint :contract_record_id, null: false

      t.timestamps

      t.index :ocid
      t.index :expired_record
      t.index :submitted_by_id
    end
    add_foreign_key :non_cashable_savings, :contracts, column: 'contract_record_id', primary_key: 'record_id'

    create_table :non_monetisable_savings do |t|
      t.boolean :expired_record
      t.datetime :expired_date_time
      t.string :ocid
      t.string :savings_type
      t.bigint :submitted_by_id
      t.bigint :contract_record_id, null: false

      t.timestamps

      t.index :ocid
      t.index :expired_record
      t.index :submitted_by_id
    end
    add_foreign_key :non_monetisable_savings, :contracts, column: 'contract_record_id', primary_key: 'record_id'
  end
end
