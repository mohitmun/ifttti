class CreateReceipes < ActiveRecord::Migration
  def change
    create_table :receipes do |t|

      t.timestamps null: false
    end
  end
end
