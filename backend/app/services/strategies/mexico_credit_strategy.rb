# Estrategia específica para procesar solicitudes de crédito en México
module Strategies
  class MexicoCreditStrategy < CreditApplicationStrategy
  def process
    # Lógica específica para México
    # Aquí puedes agregar validaciones, llamadas a APIs externas,
    # cálculos específicos, etc.

    Rails.logger.info "Procesando solicitud de crédito para México - ID: #{credit_application.id}"

    # Ejemplo de lógica específica para México
    perform_mexico_specific_processing

    { success: true, country: "mexico", message: "Solicitud procesada con estrategia de México" }
  end

  private

  def perform_mexico_specific_processing
    CreditRulesValidation::Mexico::ValidationJob.perform_later(credit_application.id)
    # Agregar el job para solicitar `banking_data`
    BankingProviderSimulationJob.perform_later(credit_application.id)
  end
  end
end
