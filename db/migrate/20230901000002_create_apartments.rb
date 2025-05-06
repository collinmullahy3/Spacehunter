class CreateApartments < ActiveRecord::Migration
  def change
    create_table :apartments do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :address, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip, null: false
      t.integer :bedrooms, null: false, default: 1
      t.decimal :bathrooms, precision: 3, scale: 1, null: false, default: 1.0
      t.integer :square_feet
      t.boolean :available, default: true
      t.date :available_from
      t.boolean :pet_friendly, default: false
      t.boolean :furnished, default: false
      t.boolean :parking, default: false
      t.boolean :air_conditioning, default: false
      t.integer :view_count, default: 0
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
    
    add_index :apartments, :price
    add_index :apartments, :bedrooms
    add_index :apartments, :bathrooms
    add_index :apartments, :city
    add_index :apartments, :available
  end
end
