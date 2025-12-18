module CreditRulesValidation
  module Mexico
    class IdentityDocumentFullnameSpecification
      def self.satisfied_by?(credit_application)
        banking_data = credit_application.banking_data || {}
        name = banking_data[:name] || banking_data["name"]
        lastname = banking_data[:lastname] || banking_data["lastname"]

        return false if credit_application.full_name.blank?
        return false if name.blank? || lastname.blank?

        # Normalizar ambos nombres: eliminar espacios extra, convertir a minúsculas
        full_name_from_banking = "#{name} #{lastname}".squish.downcase.strip
        credit_application_full_name = credit_application.full_name.to_s.squish.downcase.strip

        full_name_from_banking == credit_application_full_name
      rescue => e
        Rails.logger.warn("IdentityDocumentFullnameSpecification error: #{e.message}")
        false
      end
    end
  end
end
