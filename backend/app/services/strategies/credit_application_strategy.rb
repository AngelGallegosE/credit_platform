# Clase base abstracta para las estrategias de solicitud de crédito
module Strategies
  class CreditApplicationStrategy
    attr_reader :credit_application

    def initialize(credit_application)
      @credit_application = credit_application
    end

    # Método que debe ser implementado por las estrategias concretas
    def process
      raise NotImplementedError, "Las subclases deben implementar el método #process"
    end
  end
end
