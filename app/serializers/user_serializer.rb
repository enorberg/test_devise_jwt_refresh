class UserSerializer
  include JSONAPI::Serializer
  attributes :user_id, :email, :last_name, :nick_name

end
