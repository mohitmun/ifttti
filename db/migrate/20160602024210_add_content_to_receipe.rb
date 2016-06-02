class AddContentToReceipe < ActiveRecord::Migration
  def change
    add_column :receipes, :content, :json
  end
end
