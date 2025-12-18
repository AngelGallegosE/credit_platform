# Estrategia específica para procesar solicitudes de crédito en Portugal
module Strategies
  class PortugalCreditStrategy < CreditApplicationStrategy
    def process
      # Lógica específica para Portugal
      # Aquí puedes agregar validaciones, llamadas a APIs externas,
      # cálculos específicos, etc.

      Rails.logger.info "Procesando solicitud de crédito para Portugal - ID: #{credit_application.id}"

      # Ejemplo de lógica específica para Portugal
      perform_portugal_specific_processing

      { success: true, country: "portugal", message: "Solicitud procesada con estrategia de Portugal" }
    end

    private

    def perform_portugal_specific_processing
      # Identity document format validation doesn't need external data, so we can perform it immediately
      CreditRulesValidation::Portugal::ValidationJob.perform_later(credit_application.id, [ "identity_document_format" ])

      # Banking data simulation
      PortugalBankingProviderSimulationJob.perform_later(credit_application.id)
    end
  end
end
