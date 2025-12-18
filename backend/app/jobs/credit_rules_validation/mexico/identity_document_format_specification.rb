module CreditRulesValidation
  module Mexico
    class IdentityDocumentFormatSpecification
      def self.satisfied_by?(credit_application)
        document = credit_application.identity_document
        return false unless document.attached?
        filename = document.filename.to_s.downcase
        return false unless filename.end_with?(".file")

        content = document.download
        content = content.force_encoding("UTF-8") if content.respond_to?(:force_encoding)
        content.upcase.include?("CURP")
      rescue => e
        Rails.logger.warn("IdentityDocumentFormatSpecification error: #{e.message}")
        false
      end
    end
  end
end
