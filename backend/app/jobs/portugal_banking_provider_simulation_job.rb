class PortugalBankingProviderSimulationJob < ApplicationJob
  queue_as :default

  def perform(credit_application_id)
    credit_application = CreditApplication.find(credit_application_id)

    # Simular delay de 5 segundos (como si fuera una llamada externa)
    # sleep(5)

    # Generar datos bancarios simulados
    banking_data = generate_banking_data(credit_application)

    # Actualizar el credit_application con los datos bancarios
    update_credit_application(credit_application, banking_data)

    # Devolver los datos generados
    banking_data
  end

  private

  def generate_banking_data(credit_application)
    # Parsear el nombre completo para obtener nombre y apellido
    name_parts = credit_application.full_name.split
    first_name = name_parts.first || "Unknown"
    last_name = name_parts[1..-1]&.join(" ") || "Unknown"

    # Generar datos simulados basados en el nombre
    customer_id = "CUS-#{rand(100000..999999)}"
    base_income = rand(2000.0..5000.0).round(2)

    {
      name: first_name,
      lastname: last_name,
      customer_id: customer_id,
      date: Time.current.iso8601,
      reference_id: credit_application.id,
      country: credit_application.country,
      monthly_data: {
        income: base_income,
        average_expense: (base_income * 0.6).round(2),
        savings_rate: rand(0.2..0.5).round(2)
      },
      active_loans: generate_active_loans,
      account_status: [ "verified", "pending", "verified" ].sample,
      contact: {
        email: "#{first_name.downcase}.#{last_name.downcase.gsub(' ', '.')}@example.com",
        phone: "+351 #{rand(900000000..999999999)}"
      }
    }
  end

  def generate_active_loans
    # Simular 0-2 préstamos activos
    num_loans = rand(0..2)
    return [] if num_loans.zero?

    num_loans.times.map do |i|
      loan_amount = rand(10000..30000)
      remaining = rand((loan_amount * 0.3).to_i..(loan_amount * 0.8).to_i)

      {
        loan_id: "LO-#{Time.current.year}-#{rand(1000..9999)}",
        type: [ "personal", "car", "mortgage" ].sample,
        amount: loan_amount,
        remaining_balance: remaining,
        monthly_payment: (remaining / rand(12..60)).round(2),
        status: "active"
      }
    end
  end

  def update_credit_application(credit_application, banking_data)
    # Guardar todos los datos bancarios en el campo jsonb
    credit_application.banking_data = banking_data

    # Actualizar monthly_income si viene en los datos
    monthly_income = banking_data.dig(:monthly_data, :income) || banking_data.dig("monthly_data", "income")
    if monthly_income.present?
      credit_application.monthly_income = monthly_income
      # Trigger validation with requested amount vs monthly income validation
      CreditRulesValidation::Portugal::ValidationJob.perform_later(credit_application.id, [ "requested_amount_vs_monthly_income" ])
    end

    credit_application.save!
  end
end
