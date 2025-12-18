class CreditApplication < ApplicationRecord
  # ActiveStorage attachment para identity_document
  has_one_attached :identity_document

  # Relaciones
  belongs_to :user
  has_many :credit_application_events, dependent: :destroy

  # Enums
  enum :status, {
    pending: "pending",
    preapproved: "preapproved",
    manual_required: "manual_required",
    country_validated: "country_validated",
    country_invalidated: "country_invalidated",
    in_review: "in_review",
    approved: "approved",
    rejected: "rejected",
    expired: "expired",
    cancelled: "cancelled"
  }

  # Callbacks
  after_update :notify_status_change, if: :saved_change_to_status?
  after_create :invalidate_count_cache
  after_update :invalidate_count_cache, if: -> { saved_change_to_country? || saved_change_to_status? }
  after_destroy :invalidate_count_cache

  # Validaciones
  validates :country, presence: true
  validates :full_name, presence: true
  validates :requested_amount, presence: true, numericality: { greater_than: 0 }
  validates :application_date, presence: true
  validates :monthly_income, numericality: { greater_than: 0 }, allow_nil: true

  # Scopes para filtros
  scope :by_country, ->(country) { where(country: country) if country.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }

  # Método de clase para paginación y filtrado
  def self.filtered_and_paginated(filters = {}, page: 1, per_page: 30)
    applications = all
    applications = applications.by_country(filters[:country]) if filters[:country].present?
    applications = applications.by_status(filters[:status]) if filters[:status].present?

    page = page.to_i.positive? ? page.to_i : 1
    offset = (page - 1) * per_page

    # Cachear el total_count por 5 minutos
    cache_key = count_cache_key(filters)
    total_count = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      applications.count
    end

    paginated_applications = applications.recent.limit(per_page).offset(offset)

    {
      data: paginated_applications,
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  # Genera la clave de cache para el conteo basado en los filtros
  def self.count_cache_key(filters = {})
    country = filters[:country] || "all"
    status = filters[:status] || "all"
    "credit_applications_count:#{country}:#{status}"
  end

  def self.status_counts_by_country(country_filter = nil)
    countries = country_filter.present? ? [ country_filter ] : [ "mexico", "portugal" ]

    result = {}
    countries.each do |country|
      counts = where(country: country).group(:status).count
      country_key = country_mapping_to_code(country)

      # Incluimos todos los estados definidos en el enum para que la gráfica sea consistente
      result[country_key] = self.statuses.keys.each_with_object({}) do |status, status_counts|
        status_counts[status] = counts[status] || 0
      end
    end
    result
  end

  def self.country_mapping_to_code(country)
    {
      "mexico" => "MX",
      "portugal" => "PT"
    }[country.downcase] || country.upcase
  end

  def self.code_to_country_mapping(code)
    {
      "MX" => "mexico",
      "PT" => "portugal"
    }[code.upcase] || code.downcase
  end

  private

  def notify_status_change
    NotificationService.notify_status_change(self)
  end

  def invalidate_count_cache
    # Invalidar todos los caches de conteo posibles
    Rails.cache.delete(self.class.count_cache_key({}))
    Rails.cache.delete(self.class.count_cache_key({ country: country }))
    Rails.cache.delete(self.class.count_cache_key({ status: status }))
    Rails.cache.delete(self.class.count_cache_key({ country: country, status: status }))

    # También invalidar el cache del país anterior si cambió
    if saved_change_to_country
      old_country = saved_change_to_country[0]
      Rails.cache.delete(self.class.count_cache_key({ country: old_country }))
      Rails.cache.delete(self.class.count_cache_key({ country: old_country, status: status }))
    end

    # También invalidar el cache del status anterior si cambió
    if saved_change_to_status
      old_status = saved_change_to_status[0]
      Rails.cache.delete(self.class.count_cache_key({ status: old_status }))
      Rails.cache.delete(self.class.count_cache_key({ country: country, status: old_status }))
    end
  end
end
