class Users::RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]

  # POST: /api/users/sign_up
  # params: { username: string, email: string, password: string, password_confirmation: string }
  def create
    user = User.new(user_params)

    if user.save
      render json: user, serializer: CurrentUserSerializer, status: 201
    else
      render json: { errors: user.errors.full_messages }, status: 422
    end
  end

  private

  def user_params
    params.permit(:username, :email, :password, :password_confirmation)
  end
end
