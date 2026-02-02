class CreateSmComments < ActiveRecord::Migration[8.0]
  def change
    create_table :sm_comments do |t|
      t.references :issue, foreign_key: { to_table: :sm_issues }, null: false
      t.references :author, foreign_key: { to_table: :users }, null: true
      t.text :body, null: false

      t.timestamps
    end
  end
end
