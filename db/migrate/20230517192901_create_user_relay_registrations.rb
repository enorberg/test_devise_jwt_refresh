class CreateUserRelayRegistrations < ActiveRecord::Migration[7.0]
  def change
    create_table :user_relay_registrations do |t|
      t.string :user_id
      t.string :device_guid
      t.string :device_description
      t.integer :usage_count

      t.timestamps
    end
  end
end
