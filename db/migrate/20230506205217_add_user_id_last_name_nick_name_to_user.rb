class AddUserIdLastNameNickNameToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :user_id, :string
    add_column :users, :last_name, :string
    add_column :users, :nick_name, :string
  end
end
