# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include RackSessionsFix
  require 'jwt'

  respond_to :json

  def create
    #logger.info "login: params: #{params.inspect}"
    logger.info "login: params: create()"
    if params[:user][:jwt_rrt]
      #logger.info "...user.jwt_rrt: #{params[:user][:jwt_rrt]}"
      current_user = User.find_by user_id: params[:user][:user_id]

     # return Hash: {status: jwt_status, user_id: user_id, device_guid: device_guid}
      chk_hsh = check_rrt_jwt(params[:user][:jwt_rrt])
      if (current_user == nil) || (chk_hsh[:status] == false)
        respond_with_error()
      else
        #logger.info "...current_user.user_id: #{current_user.user_id} - jwt_rrt.user_id #{chk_hsh[:user_id]}"
        #logger.info "...user.relay_id: #{params[:user][:relay_id]} - jwt_rrt.device_guid #{chk_hsh[:device_guid]}"
        if current_user.user_id == chk_hsh[:user_id] && params[:user][:relay_id] == chk_hsh[:device_guid]
          logger.info "...check the user_relay_registration entry..."
          rrt = UserRelayRegistration.find_by user_id: chk_hsh[:user_id], device_guid: chk_hsh[:device_guid]
          if rrt != nil
            logger.info "...do the jwt_rrt login..."
            sign_in(:user, current_user)
            respond_with(current_user)
          else
            respond_with_error()
          end
        else
          respond_with_error()
        end
      end

    else   #..convetional user_id & pwd login....
      super
    end
  end

  private

  def respond_with_error
    render json: {
      status: { 
        code: 401, message: 'Invalid credentials.',
      }
    }, status: 401
  end

  def respond_with(current_user, _opts = {})
    render json: {
      status: { 
        code: 200, message: 'Login  successfull.',
        data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
      }
    }, status: :ok
  end

  def respond_to_on_destroy
    if request.headers['Authorization'].present?
      jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
      current_user = User.find(jwt_payload['sub'])
    end
    
    if current_user
      render json: {
        status: 200,
        message: 'Logged out successfully.'
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end


  def decrypt text
    salt, data = text.split "$$"

    len   = ActiveSupport::MessageEncryptor.key_len
    key   = ActiveSupport::KeyGenerator.new(
            Rails.application.secrets.secret_key_base).generate_key salt, len
    crypt = ActiveSupport::MessageEncryptor.new key
    crypt.decrypt_and_verify data
  end


  
  # De-construct the RRT JWT and check for valid format...
  # Claims payload consists of:
  #   iss: https://popps.com"
  #   sub: ...encrypted user_id and device_guid Hash
  #   popps_type: "rrt"
  #
  # Note: the expiration claim is OPTIONAL - leave it out for perpetual JWT.

  def check_rrt_jwt(token)
    hmac_secret = Rails.application.secrets.secret_key_base

    #  TRY .....
    payload = JWT.decode token, hmac_secret, true, { algorithm: 'HS256' }
    #logger.info "...check_rrt_jwt() - JWT.decode(): #{payload}"

    #  ????? Note: payload is a 2 entry array - [claims, {"alg"=>"HS256}]
    claims = payload[0]
    #logger.info "...check_rrt_jwt() - claims: #{claims}"
    #logger.info "...check_rrt_jwt() - claims(iss): #{claims["iss"]}"
    #logger.info "...check_rrt_jwt() - claims(:popps_type): #{claims["popps_type"]}"
    #logger.info "...check_rrt_jwt() - claims(sub): #{claims["sub"]}"
 
    if (claims["iss"] != "https://popps.com" || claims["popps_type"] != "rrt")
      logger.info "...invalid iss or popps_type"
      return {status: false}
    end

    dec_sub = decrypt claims["sub"]
    logger.info "...check_rrt_jwt() - decrypt(claims[sub]): #{dec_sub}"

    #payload_hsh1 = JSON.load dec_payload  //this doesn't work ??  - use eval() instead
    payload_hsh1 = eval(dec_sub)

    uid = payload_hsh1[:user_id]
    gid = payload_hsh1[:device_guid]
    logger.info "...create() - user_id: #{uid} device_guid: #{gid}"
  
    {status: true, user_id: uid, device_guid: gid }

  end
  
  
 end
  
  
 
