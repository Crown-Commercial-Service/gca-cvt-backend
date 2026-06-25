class CreateContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :contracts, id: :integer, primary_key: :record_id do |t|
      t.datetime :record_inserted_date
      t.boolean :expired_record, default: false, null: false
      t.datetime :expired_date_time
      t.string :ocid
      t.string :tender_id
      t.string :organisation_id
      t.string :organisation_name
      t.decimal :amount, precision: 15, scale: 2
      t.string :currency
      t.datetime :start_date
      t.datetime :end_date
      t.string :title
      t.string :description
      t.string :cpv_code
      t.string :cpv_description
      t.string :notice_type
      t.datetime :published_date
      t.string :source_api
      t.datetime :tender_period_end_date
      t.datetime :award_date
      t.boolean :calculation_completed, default: false, null: false

      t.index :ocid
      t.index :tender_id
      t.index :organisation_id
      t.index :expired_record
    end
  end
end
