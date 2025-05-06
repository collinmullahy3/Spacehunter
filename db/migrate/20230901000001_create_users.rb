class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      # Devise fields
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      
      # Custom fields
      t.string :name
      t.string :phone
      t.text :bio
      t.string :role, default: "renter"
      t.boolean :admin, default: false

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
