class AddContentToUser < ActiveRecord::Migration
  def change
    add_column :users, :content, :json
  end
end
