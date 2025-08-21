class CreateClaims < ActiveRecord::Migration[7.2]
  def change
    create_table :claims, id: :uuid do |t|
      t.uuid :customer_id, null: false
      t.string :claim_type, null: false
      t.text :description, null: false
      t.decimal :amount_claimed, default: 0.0
      t.string :status, default: 'submitted'
      t.boolean :is_duplicate, default: false

      t.timestamps with_deleted_at: true
    end

    add_named_index :claims, :customer_id
    add_named_index :claims, %i[is_duplicate status]

    add_deleted_at_index :claims

    add_foreign_key :claims, :customers, column: :customer_id, type: :uuid
  end
end
