class CreateSmBoards < ActiveRecord::Migration[8.0]
  def change
    create_table :sm_boards do |t|
      t.references :project, foreign_key: { to_table: :sm_projects }, null: false
      t.string :name, null: false
      t.jsonb :columns, default: []

      t.timestamps
    end
  end
end
