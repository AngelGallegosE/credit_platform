module CreditRulesValidation
  module Mexico
    class RequestedAmountMonthlyIncomeSpecification
      def self.satisfied_by?(credit_application)
        monthly_income = credit_application.monthly_income
        requested_amount = credit_application.requested_amount

        return false if monthly_income.blank? || requested_amount.blank?

        threshold = monthly_income.to_d * BigDecimal("0.3")
        requested_amount.to_d <= threshold
      rescue => e
        Rails.logger.warn("RequestedAmountMonthlyIncomeSpecification error: #{e.message}")
        false
      end
    end
  end
end
