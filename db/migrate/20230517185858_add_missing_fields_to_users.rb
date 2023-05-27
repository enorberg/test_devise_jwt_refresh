class AddMissingFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :cell_number, :string
    add_column :users, :pin, :integer
    add_column :users, :age_at_signup, :integer
    add_column :users, :date_of_signup, :date
    add_column :users, :admin_flg, :boolean
  end
end
