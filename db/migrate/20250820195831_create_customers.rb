class CreateCustomers < ActiveRecord::Migration[7.2]
  def change
    create_table :customers, id: :uuid do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :status, null: false, default: "active"

      t.timestamps with_deleted_at: true
    end

    add_named_index :customers, :email, unique: true
  end
end
