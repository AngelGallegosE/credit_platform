module CreditRulesValidation
  module Mexico
    class ValidationJob < ApplicationJob
      def perform(credit_application_id)
        credit_application = CreditApplication.find(credit_application_id)
        validation_result = validate_credit_rules(credit_application)
        credit_application.update(validation_result: validation_result)

        # Actualizar status según el resultado de las validaciones
        # El callback after_update en el modelo se encargará de enviar la notificación
        if all_validations_passed?(validation_result)
          credit_application.update(status: "country_validated")
        else
          credit_application.update(status: "country_invalidated")
        end
      end

      private

      def validate_credit_rules(credit_application)
        specifications = {
          identity_document_format: CreditRulesValidation::Mexico::IdentityDocumentFormatSpecification,
          identity_document_fullname: CreditRulesValidation::Mexico::IdentityDocumentFullnameSpecification,
          requested_amount_vs_monthly_income: CreditRulesValidation::Mexico::RequestedAmountMonthlyIncomeSpecification
        }

        specifications.map do |name, spec_class|
          { name: name, result: spec_class.satisfied_by?(credit_application) }
        end
      end

      def all_validations_passed?(validation_result)
        validation_result.all? do |validation|
          result = validation[:result] || validation["result"]
          result == true
        end
      end
    end
  end
end
