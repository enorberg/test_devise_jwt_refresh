class Api::V1::UserRelayRegistrationsController < Api::V1::BaseController
  require 'jwt'
  before_action :authenticate_user!
  before_action :set_rrt, only: [ :show, :update, :destroy ]


  logger.info "Api::V1::UserRelayRegistrationsController"

  #  ?? 
  #  - How to check JWT_UAT user_id  vs  params.user_id ??
  #  - How to leave out  index ??
  #
  
  def index
  end

  def show
    logger.info "UserRelayRegistrations::show() for authenticated user: #{current_user.user_id} "
    render json: @rrt
  end

  def create
    @rrt = UserRelayRegistration.new(user_params)
    if @rrt.save
      # compute RRT_JWT and return it.
      tkn = new_rrt_jwt  @rrt.user_id, @rrt.device_guid 
      render json: {rrt_jwt: tkn, status: :created}
    else
      render_error
    end
  end

  def update
    if @rrt.update(user_params)
      render :show
    else
      render_error
    end
  end

  def destroy
    @rrt.destroy
    head :no_content
  end


  private

  def set_rrt
    @rrt = UserRelayRegistration.find(params[:id])
  end

  def user_params
    params.require(:user_relay_registration).permit(:id, :user_id, :device_guid, :device_description, :usage_count )
  end

  def render_error
    render json: { errors: @rrt.errors.full_messages },
      status: :unprocessable_entity
  end

  def encrypt text
    text = text.to_s unless text.is_a? String

    len   = ActiveSupport::MessageEncryptor.key_len
    salt  = SecureRandom.hex len
    key   = ActiveSupport::KeyGenerator.new(
            Rails.application.secrets.secret_key_base).generate_key salt, len
    crypt = ActiveSupport::MessageEncryptor.new key
    encrypted_data = crypt.encrypt_and_sign text
    "#{salt}$$#{encrypted_data}"
  end

  def decrypt text
    salt, data = text.split "$$"

    len   = ActiveSupport::MessageEncryptor.key_len
    key   = ActiveSupport::KeyGenerator.new(
            Rails.application.secrets.secret_key_base).generate_key salt, len
    crypt = ActiveSupport::MessageEncryptor.new key
    crypt.decrypt_and_verify data
  end


  # Construct a New JWT for User Relay Registration - RRT
  # Claims consist of:
  #   iss: https://popps.com"
  #   sub: ...encrypted user_id and device_guid Hash
  #   popps_type: "rrt"
  #
  # Note: the expiration claim is OPTIONAL - leave it out for perpetual JWT.

  def new_rrt_jwt(id, guid)

    sub_hash = { user_id: @rrt.user_id, device_guid: @rrt.device_guid }
    sub_tos = sub_hash.to_s
    logger.info "...create() - sub_hsh.to_s: #{sub_tos}"
    
    enc_sub = encrypt sub_tos
    logger.info "...create() - encrypt(sub_tos): #{enc_sub}"

    payload = { iss: "https://popps.com", sub: enc_sub, popps_type: "rrt" }
    hmac_secret = Rails.application.secrets.secret_key_base
    token = JWT.encode payload, hmac_secret, 'HS256'
  end


end
