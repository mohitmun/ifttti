class AddUserIdToReceipe < ActiveRecord::Migration
  def change
    add_column :receipes, :user_id, :integer
  end
end
