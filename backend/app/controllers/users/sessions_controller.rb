class Users::SessionsController < Devise::SessionsController
  respond_to :json

  after_action :inject_jwt_token, only: :create

  def create
    self.resource = warden.authenticate(auth_options)

    if resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      render json: { message: "Invalid Email or password." }, status: :unauthorized
    end
  end

  private

  def inject_jwt_token
    return unless response.status == 200

    auth_header = response.headers["Authorization"]
    token = auth_header&.split(" ")&.last || request.env["warden-jwt_auth.token"]

    if token && response.content_type&.include?("application/json")
      begin
        body = JSON.parse(response.body)
        body["token"] = token
        response.body = body.to_json
      rescue JSON::ParserError
      end
    end
  end

  def respond_with(resource, _opts = {})
    token = request.env["warden-jwt_auth.token"]

    render json: {
      message: "Logged in successfully",
      token: token,
      user: {
        id: resource.id,
        email: resource.email,
        full_name: resource.full_name,
        role: resource.role
      }
    }, status: :ok
  end

  def respond_to_on_destroy
    render json: { message: "Logged out" }, status: :ok
  end
end
