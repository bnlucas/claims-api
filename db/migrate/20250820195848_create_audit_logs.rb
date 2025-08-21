class CreateAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_logs, id: :uuid do |t|
      t.uuid :customer_id, null: false
      t.uuid :claim_id, null: false
      t.string :actor_id, null: false
      t.string :action, null: false
      t.text :details, null: false

      t.timestamps with_deleted_at: false
    end

    add_named_index :audit_logs, %i[customer_id claim_id actor_id]

    add_foreign_key :audit_logs, :customers, column: :customer_id, type: :uuid
    add_foreign_key :audit_logs, :claims, column: :claim_id, type: :uuid
  end
end
