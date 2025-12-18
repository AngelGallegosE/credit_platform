class ProcessBankingDataWebhookService
  attr_reader :params, :errors

  def initialize(params)
    @params = params
    @errors = []
  end

  def call
    credit_application = find_credit_application

    unless credit_application
      Rails.logger.warn "No se encontró solicitud de crédito para: reference_id=#{params[:reference_id]}, name=#{params[:name]}, lastname=#{params[:lastname]}, country=#{params[:country]}"
      return {
        success: false,
        errors: [ "No se encontró una solicitud de crédito para los datos proporcionados" ]
      }
    end

    Rails.logger.info "Solicitud encontrada: ID=#{credit_application.id}, Country=#{credit_application.country}"

    update_credit_application(credit_application)
    trigger_validation(credit_application)

    {
      success: true,
      credit_application_id: credit_application.id
    }
  rescue StandardError => e
    Rails.logger.error "Error en ProcessBankingDataWebhookService: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    {
      success: false,
      errors: [ e.message ]
    }
  end

  private

  def find_credit_application
    # Prioridad 1: Buscar por reference_id (ID interno) y país
    # Los parámetros pueden venir como símbolos o strings, normalizamos
    reference_id = params[:reference_id] || params["reference_id"]
    country_param = params[:country] || params["country"]

    # Manejar caso donde reference_id puede ser un Array
    reference_id = reference_id.first if reference_id.is_a?(Array)
    reference_id = reference_id.to_i if reference_id.present?

    # Manejar country también
    country = country_param
    country = country.first if country.is_a?(Array)
    country = country&.to_s&.downcase

    if reference_id.present? && reference_id.is_a?(Integer)
      Rails.logger.info "Buscando por reference_id: #{reference_id}, country: #{country}"
      credit_application = CreditApplication.find_by(
        id: reference_id,
        country: country
      )
      return credit_application if credit_application
    end

    # Prioridad 2: Buscar por nombre completo y país (fallback)
    name = params[:name] || params["name"]
    lastname = params[:lastname] || params["lastname"]

    # Manejar caso donde pueden ser arrays
    name = name.first if name.is_a?(Array)
    lastname = lastname.first if lastname.is_a?(Array)
    country = country_param
    country = country.first if country.is_a?(Array)
    country = country&.to_s&.downcase

    full_name = "#{name} #{lastname}".strip

    Rails.logger.info "Buscando por nombre: #{full_name}, country: #{country}"

    CreditApplication.find_by(
      full_name: full_name,
      country: country
    )
  end

  def update_credit_application(credit_application)
    # Guardar todos los datos bancarios en el campo jsonb
    credit_application.banking_data = params.to_h

    # Actualizar monthly_income si viene en los datos
    # Manejar tanto símbolos como strings (JSON puede venir como strings)
    monthly_income = params.dig(:monthly_data, :income) || params.dig("monthly_data", "income")
    if monthly_income.present?
      credit_application.monthly_income = monthly_income
    end

    credit_application.save!
  end

  def trigger_validation(credit_application)
    return unless credit_application.country.to_s.downcase == "mexico"

    CreditRulesValidation::Mexico::ValidationJob.perform_now(credit_application.id)
  rescue StandardError => e
    Rails.logger.warn "No se pudo ejecutar la validación para la solicitud #{credit_application.id}: #{e.class} - #{e.message}"
  end
end
