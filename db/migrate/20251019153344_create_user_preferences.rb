class CreateUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_preferences do |t|
      # Foreign key to users table - unique index enforces one-to-one relationship
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      # User preference fields (nullable - user may not have set preferences yet)
      t.string :budget
      t.string :accommodation
      t.string :activities
      t.string :eating_habits

      t.timestamps null: false
    end
  end
end
