class User::RegistrationsController < Devise::RegistrationsController

  def new
    super
    @is_using_email = true
  end

  def create
    super
    @is_using_email = (params[:user] and !params[:user][:email].nil?)
  end
end
