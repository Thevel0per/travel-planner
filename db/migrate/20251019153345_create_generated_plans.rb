class CreateGeneratedPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :generated_plans do |t|
      # Foreign key to trips table - index optimizes fetching plans for a trip
      t.references :trip, null: false, foreign_key: true, index: true

      # AI-generated plan content
      t.text :content, null: false

      # Status tracking for generation process
      # Expected values (managed at application level): 'pending', 'generating', 'completed', 'failed'
      t.string :status, null: false, default: 'pending'

      # User feedback rating (1-10, nullable until user provides feedback)
      t.integer :rating

      t.timestamps null: false
    end

    # Index for filtering by generation status
    add_index :generated_plans, :status, name: 'index_generated_plans_on_status'
  end
end
