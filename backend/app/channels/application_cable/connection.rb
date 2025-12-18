module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = extract_token_from_params

      unless token
        reject_unauthorized_connection("Token no encontrado")
        return
      end

      begin
        decoded_token = decode_token(token)
        return reject_unauthorized_connection("Token inválido") unless decoded_token

        subject = decoded_token["sub"] || decoded_token["jti"]
        return reject_unauthorized_connection("Subject no encontrado") unless subject

        # Buscar usuario por ID o jti
        user = if subject.to_s.match?(/^\d+$/)
                 User.find_by(id: subject.to_i)
        else
                 User.find_by(jti: subject)
        end

        return reject_unauthorized_connection("Usuario no encontrado") unless user

        # Verificar si el token está revocado
        if JwtDenylist.exists?(jti: user.jti)
          reject_unauthorized_connection("Token revocado")
          return
        end

        user
      rescue JWT::DecodeError => e
        Rails.logger.error "JWT Decode Error en ActionCable: #{e.message}"
        reject_unauthorized_connection("Error al decodificar el token")
      rescue JWT::ExpiredSignature => e
        Rails.logger.error "JWT Expired en ActionCable: #{e.message}"
        reject_unauthorized_connection("Token expirado")
      rescue JWT::VerificationError => e
        Rails.logger.error "JWT Verification Error en ActionCable: #{e.message}"
        reject_unauthorized_connection("Error de verificación del token")
      rescue => e
        Rails.logger.error "Error inesperado en ActionCable: #{e.class} - #{e.message}"
        reject_unauthorized_connection("Error inesperado en la autenticación")
      end
    end

    def extract_token_from_params
      # El token puede venir en los parámetros de la conexión WebSocket
      # Formato: ws://host/cable?token=xxx o en el header Authorization
      token = request.params[:token]

      # Si no está en params, intentar desde el header Authorization
      unless token
        auth_header = request.headers["Authorization"] || request.headers["authorization"]
        if auth_header&.start_with?("Bearer ")
          token = auth_header.split(" ").last
        end
      end

      token
    end

    def decode_token(token)
      secret = Devise::JWT.config.secret
      secret ||= ENV["DEVISE_JWT_SECRET_KEY"]
      secret ||= Rails.application.secret_key_base

      unless secret
        raise "JWT secret key not configured"
      end

      decoded = JWT.decode(token, secret, true, { algorithm: "HS256" })
      decoded[0]
    end
  end
end
