class UserRelayRegistration < ApplicationRecord

  validates_uniqueness_of   :device_guid, scope: :user_id

end
