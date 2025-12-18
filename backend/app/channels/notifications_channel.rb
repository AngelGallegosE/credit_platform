class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # Crear un stream único por usuario autenticado
    stream_from "notifications:#{current_user.id}"
  end

  def unsubscribed
    # Cualquier limpieza necesaria cuando el usuario se desconecta
  end
end
