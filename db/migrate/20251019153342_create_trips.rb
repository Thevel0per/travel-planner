class CreateTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :trips do |t|
      # Foreign key to users table
      t.references :user, null: false, foreign_key: true, index: false

      # Trip details
      t.string :name, null: false
      t.string :destination, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :number_of_people, null: false, default: 1

      t.timestamps null: false
    end

    # Composite index for optimized user trip queries, chronologically ordered
    add_index :trips, [ :user_id, :start_date ], name: 'index_trips_on_user_id_and_start_date'

    # Index for destination-based queries
    add_index :trips, [ :user_id, :destination ], name: 'index_trips_on_user_id_and_destination'
  end
end
