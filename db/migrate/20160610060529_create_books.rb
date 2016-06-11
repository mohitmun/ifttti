class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.integer :user_id
      t.text :title
      t.text :isbn
      t.text :author
      t.text :cover_image
      t.json :content

      t.timestamps null: false
    end
  end
end
