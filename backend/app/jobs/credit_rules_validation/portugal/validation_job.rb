module CreditRulesValidation
  module Portugal
    class ValidationJob < ApplicationJob
      def perform(credit_application_id, validation_names = nil)
        credit_application = CreditApplication.find(credit_application_id)
        validation_result = validate_credit_rules(credit_application, validation_names)

        # Actualizar status según el resultado de las validaciones
        # El callback after_update en el modelo se encargará de enviar la notificación
        if all_validations_passed?(validation_result)
          credit_application.update(status: "country_validated")
        else
          credit_application.update(status: "country_invalidated")
        end
      end

      private

      def validate_credit_rules(credit_application, validation_names = nil)
        all_specifications = {
          identity_document_format: CreditRulesValidation::Portugal::IdentityDocumentFormatSpecification,
          requested_amount_vs_monthly_income: CreditRulesValidation::Portugal::RequestedAmountMonthlyIncomeSpecification
        }

        # Si se especifican validaciones, filtrar solo esas; si no, usar todas
        specifications = if validation_names.present?
          # Convertir a símbolos si vienen como strings
          requested_names = validation_names.map(&:to_sym)
          all_specifications.select { |name, _| requested_names.include?(name) }
        else
          all_specifications
        end

        # Ejecutar cada validación y actualizar el resultado conforme se ejecuta
        results = specifications.map do |name, spec_class|
          result = spec_class.satisfied_by?(credit_application)

          # Actualizar solo esta validación en el validation_result
          update_validation_result(credit_application, name.to_s, result)

          { name: name, result: result }
        end

        results
      end

      def update_validation_result(credit_application, validation_name, validation_result)
        # Recargar el credit_application para obtener el validation_result más actualizado
        credit_application.reload
        current_validation_result = credit_application.validation_result || []

        # Convertir el array actual a un formato más fácil de manipular
        # Normalizar a strings para las keys
        validation_array = current_validation_result.map do |item|
          {
            "name" => item[:name] || item["name"],
            "result" => item[:result] || item["result"]
          }
        end

        # Buscar si la validación ya existe
        existing_index = validation_array.find_index { |item| item["name"] == validation_name }

        if existing_index
          # Actualizar el resultado existente
          validation_array[existing_index]["result"] = validation_result
        else
          # Agregar nueva validación
          validation_array << { "name" => validation_name, "result" => validation_result }
        end

        # Actualizar el credit_application con el nuevo validation_result
        credit_application.update(validation_result: validation_array)
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
