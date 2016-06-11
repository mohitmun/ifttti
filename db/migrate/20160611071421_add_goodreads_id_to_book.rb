class AddGoodreadsIdToBook < ActiveRecord::Migration
  def change
    add_column :books, :goodreads_id, :integer
  end
end
