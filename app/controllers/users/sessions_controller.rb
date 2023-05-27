# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include RackSessionsFix

  respond_to :json

  def create
    logger.info "login: params: #{params.inspect}"
    if params[:user][:jwt_rrt]
      logger.info "...user.relay_id: #{params[:user][:relay_id]} user.jwt_rrt: #{params[:user][:jwt_rrt]}"
      # -- HACK around Devise/warden std ops....
      if params[:user][:jwt_rrt] == params[:user][:relay_id]
        logger.info "...do the jwt_rrt login..."
        @user = User.find_by user_id: params[:user][:user_id]
        if @user != nil
          sign_in(:user, @user)
          respond_with(@user)
        else
          respond_with_error()
        end
      else
        respond_with_error()
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

end
