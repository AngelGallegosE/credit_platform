class CreateCreditApplicationService
  attr_reader :params, :errors

  def initialize(params)
    @params = params
    @errors = []
  end

  def call
    credit_application = build_credit_application

    if credit_application.save
      # Adjuntar el documento después de guardar el objeto
      attach_identity_document(credit_application) if params[:identity_document].present?

      # Aplicar la estrategia correspondiente según el país
      strategy_result = CreditApplicationStrategySelector.select(credit_application)

      {
        success: true,
        credit_application: credit_application,
        strategy_result: strategy_result
      }
    else
      { success: false, errors: credit_application.errors.full_messages }
    end
  end

  private

  def build_credit_application
    CreditApplication.new(
      country: params[:country],
      full_name: params[:full_name],
      requested_amount: params[:requested_amount],
      status: params[:status],
      application_date: Time.current,
      user_id: params[:user_id]
    )
  end

  def attach_identity_document(credit_application)
    credit_application.identity_document.attach(params[:identity_document])
  end
end
