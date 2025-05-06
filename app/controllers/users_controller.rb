class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update]
  before_action :authorize_user!, only: [:edit, :update]
  
  def show
    @apartments = @user.apartments.paginate(page: params[:page], per_page: 6)
  end
  
  def edit
  end
  
  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'Profile was successfully updated.'
    else
      render :edit
    end
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:name, :phone, :bio, :avatar)
  end
  
  def authorize_user!
    unless current_user == @user || current_user.admin?
      redirect_to user_path(current_user), alert: 'You are not authorized to edit this profile.'
    end
  end
end