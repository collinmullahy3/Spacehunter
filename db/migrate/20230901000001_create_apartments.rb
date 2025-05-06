class CreateApartments < ActiveRecord::Migration[6.0]
  def change
    create_table :apartments do |t|
      t.string :title, null: false
      t.text :description
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :bedrooms, default: 0
      t.decimal :bathrooms, precision: 3, scale: 1, default: 0.0
      t.integer :square_feet
      t.date :available_date

      t.timestamps
    end
    
    add_index :apartments, :city
    add_index :apartments, :price
    add_index :apartments, :bedrooms
  end
end