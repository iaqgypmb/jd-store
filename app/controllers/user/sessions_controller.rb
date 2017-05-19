class User::SessionsController < Devise::RegistrationsController

  def new
    @user = User.new
  end

  def create
    super
  end

  def destroy
  super
  cookies.delete :user_uuid
  flash[:notice] = "退出成功"
  end

end
