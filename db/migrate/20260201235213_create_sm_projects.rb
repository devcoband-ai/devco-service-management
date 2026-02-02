class CreateSmProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :sm_projects do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.references :lead, foreign_key: { to_table: :users }, null: true
      t.string :status, default: "active", null: false

      t.timestamps
    end

    add_index :sm_projects, :key, unique: true
  end
end
