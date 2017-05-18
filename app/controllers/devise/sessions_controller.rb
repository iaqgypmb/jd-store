class SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new

  end

  # POST /resource/sign_in
  def create
    if user = sign_in(@user)
      update_browser_uuid user.uuid

      flash[:notice] = "登陆成功"
      redirect_to root_path
    else
      flash[:notice] = "邮箱或者密码不正确"
      redirect_to new_user_session_path
    end
  end

  # DELETE /resource/sign_out
  def destroy
    sign_out
    cookies.delete :user_uuid
    flash[:notice] = "退出成功"
    redirect_to root_path
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
