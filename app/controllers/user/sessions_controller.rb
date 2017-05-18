class User::SessionsController < Devise::RegistrationsController

  def new
    super
  end

  def create
    super
  end

  def destroy
  super
  cookies.delete :user_uuid
  flash[:notice] = "退出成功"
  redirect_to root_path
end

end
