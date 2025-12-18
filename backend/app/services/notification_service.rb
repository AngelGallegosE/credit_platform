# Servicio para enviar notificaciones en tiempo real a través de ActionCable
# cuando cambia el status de una credit_application.
#
# Uso:
#   credit_application = CreditApplication.find(123)
#   credit_application.update(status: "country_validated")
#   NotificationService.notify_status_change(credit_application)
#
# La notificación se enviará automáticamente al usuario que creó la solicitud
# a través del stream "notifications:#{user_id}"
class NotificationService
  def self.notify_status_change(credit_application)
    return unless credit_application.user_id

    # Mapeo de status a mensajes descriptivos
    status_messages = {
      "pending" => "Solicitud de crédito pendiente",
      "preapproved" => "Solicitud preaprobada",
      "manual_required" => "Revisión manual requerida",
      "country_validated" => "Validaciones por país exitosas",
      "country_invalidated" => "Validaciones por país fallidas",
      "in_review" => "Solicitud en revisión",
      "approved" => "Solicitud aprobada",
      "rejected" => "Solicitud rechazada"
    }

    message = status_messages[credit_application.status] || "Estado actualizado"

    notification = {
      type: "status",
      credit_application_id: credit_application.id,
      status: credit_application.status,
      message: message
    }

    # Transmitir la notificación al stream del usuario que creó la solicitud
    ActionCable.server.broadcast(
      "notifications:#{credit_application.user_id}",
      notification
    )
  rescue => e
    Rails.logger.error "Error al enviar notificación: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
