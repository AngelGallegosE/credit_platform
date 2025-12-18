# Suprimir advertencias de deprecación de Devise relacionadas con resource hash arguments
# Estas advertencias vienen de dentro de Devise cuando llama a resource internamente
# y se resolverán cuando Devise se actualice para usar keywords en lugar de hashes
if Rails.env.development? || Rails.env.test?
  Rails.application.deprecators.each do |deprecator|
    original_behavior = deprecator.behavior
    original_behaviors = original_behavior.is_a?(Array) ? original_behavior : [ original_behavior ]

    deprecator.behavior = lambda do |message, callstack, deprecation_horizon, gem_name|
      # Ignorar advertencias específicas de Devise sobre resource hash arguments
      return if message.include?("resource received a hash argument")

      # Usar el comportamiento original para otras advertencias
      original_behaviors.each { |behavior| behavior.call(message, callstack, deprecation_horizon, gem_name) }
    end
  end
end
