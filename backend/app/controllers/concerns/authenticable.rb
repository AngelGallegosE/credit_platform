module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = extract_token_from_header
    return render_unauthorized("Token no encontrado en el header Authorization") unless token

    begin
      decoded_token = decode_token(token)
      return render_unauthorized("Token inválido o no se pudo decodificar") unless decoded_token

      # Devise-JWT usa 'sub' para el subject
      # Puede contener el ID del usuario (número) o el jti (UUID)
      subject = decoded_token["sub"] || decoded_token["jti"]

      Rails.logger.debug "Decoded token: #{decoded_token.inspect}" if Rails.env.development?
      return render_unauthorized("Subject no encontrado en el token") unless subject

      # Intentar buscar el usuario por ID si subject es numérico, sino por jti
      if subject.to_s.match?(/^\d+$/)
        # Es un ID numérico
        @current_user = User.find_by(id: subject.to_i)
      else
        # Es un jti (UUID)
        @current_user = User.find_by(jti: subject)
      end

      return render_unauthorized("Usuario no encontrado con subject: #{subject}") unless @current_user

      # Verificar si el token está en la lista de denegados usando el jti del usuario
      render_unauthorized("Token revocado") if JwtDenylist.exists?(jti: @current_user.jti)
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"
      render_unauthorized("Error al decodificar el token: #{e.message}")
    rescue JWT::ExpiredSignature => e
      Rails.logger.error "JWT Expired: #{e.message}"
      render_unauthorized("Token expirado")
    rescue JWT::VerificationError => e
      Rails.logger.error "JWT Verification Error: #{e.message}"
      render_unauthorized("Error de verificación del token: #{e.message}")
    rescue RuntimeError => e
      Rails.logger.error "Runtime Error: #{e.message}"
      render_unauthorized("Error: #{e.message}")
    rescue => e
      Rails.logger.error "Unexpected JWT Error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render_unauthorized("Error inesperado en la autenticación")
    end
  end

  def current_user
    @current_user
  end

  def authorize_admin!
    unless current_user&.role == "admin"
      render json: { error: "Acceso denegado. Se requieren permisos de administrador." }, status: :forbidden
    end
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header

    # Formato esperado: "Bearer <token>"
    auth_header.split(" ").last if auth_header.start_with?("Bearer ")
  end

  def decode_token(token)
    # Usar exactamente el mismo secreto que Devise-JWT usa para generar tokens
    # Devise-JWT obtiene el secreto de jwt.secret en la configuración
    secret = Devise::JWT.config.secret

    # Si es nil, intentar con ENV o secret_key_base como fallback
    secret ||= ENV["DEVISE_JWT_SECRET_KEY"]
    secret ||= Rails.application.secret_key_base

    unless secret
      raise "JWT secret key not configured"
    end

    Rails.logger.debug "Usando secreto para decodificar token (primeros 20 chars): #{secret.to_s[0..20]}..." if Rails.env.development?

    # Decodificar el token con el mismo algoritmo que Devise-JWT usa (HS256)
    decoded = JWT.decode(token, secret, true, { algorithm: "HS256" })
    decoded[0] # Retornar el payload (primer elemento del array)
  end

  def render_unauthorized(message = nil)
    error_message = message || "No autorizado. Token requerido."
    render json: { error: error_message }, status: :unauthorized
  end
end
