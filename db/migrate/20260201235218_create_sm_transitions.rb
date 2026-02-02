class CreateSmTransitions < ActiveRecord::Migration[8.0]
  def change
    create_table :sm_transitions do |t|
      t.references :issue, foreign_key: { to_table: :sm_issues }, null: false
      t.string :from_status, null: false
      t.string :to_status, null: false
      t.references :transitioned_by, foreign_key: { to_table: :users }, null: true
      t.datetime :transitioned_at, null: false
    end

    add_index :sm_transitions, [:issue_id, :transitioned_at]
  end
end
