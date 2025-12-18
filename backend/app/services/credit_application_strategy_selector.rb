# Selector de estrategias que elige la estrategia correcta basándose en el país
class CreditApplicationStrategySelector
  STRATEGIES = {
    "mexico" => "Strategies::MexicoCreditStrategy",
    "portugal" => "Strategies::PortugalCreditStrategy"
  }.freeze

  def self.select(credit_application)
    country = credit_application.country&.downcase

    strategy_class_name = STRATEGIES[country]

    unless strategy_class_name
      raise ArgumentError, "No se encontró estrategia para el país: #{country}. Países disponibles: #{STRATEGIES.keys.join(', ')}"
    end

    # Cargar la clase de estrategia dinámicamente
    strategy_class = strategy_class_name.constantize
    strategy = strategy_class.new(credit_application)
    strategy.process
  end
end
