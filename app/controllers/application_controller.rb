class ApplicationController < ActionController::API

    before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    #logger.info "ApplicationController with devise request."
    #logger.info "...params: #{params.inspect}"

    devise_parameter_sanitizer.permit(:sign_up, keys: %i[user_id email last_name nick_name])

    devise_parameter_sanitizer.permit(:sign_in, keys: %i[user_id password relay_id jwt_rrt])

    devise_parameter_sanitizer.permit(:account_update, keys: %i[user_id last_name nick_name])
  end

end
