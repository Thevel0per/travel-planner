class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      # Foreign key to trips table - optimized for joins and filtering
      t.references :trip, null: false, foreign_key: true, index: true

      # Note content
      t.text :content, null: false

      t.timestamps null: false
    end
  end
end
