class Api::V1::UsersController <  Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :update, :destroy ]

  logger.info "Api::V1::UsersController"
  logger.info "...#{Rails.application.credentials.devise_jwt_secret_key!} "

  def index
    @users = User.all
  end

  def show
    render json: @user
  end

  def create
    @user = User.new(user_params)
    if @user.save
      render :show, status: :created
    else
      render_error
    end
  end

  def update
    if @user.update(user_params)
      render :show
    else
      render_error
    end
  end

  def destroy
    @user.destroy
    head :no_content
  end


  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:id, :user_id, :first_name, :last_name, :nick_name, :email, :cell_number, :passwd_hash, :pin, :age_at_signup, :date_of_signup, :admin_flg, :create_time, :update_time)
  end

  def render_error
    render json: { errors: @user.errors.full_messages },
      status: :unprocessable_entity
  end

end
