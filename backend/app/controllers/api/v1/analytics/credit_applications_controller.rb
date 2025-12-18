module Api
  module V1
    module Analytics
      class CreditApplicationsController < ApplicationController
        include Authenticable

        def by_status
          country_param = params[:country]
          db_country = country_param.present? ? CreditApplication.code_to_country_mapping(country_param) : nil

          counts = CreditApplication.status_counts_by_country(db_country)

          render json: counts, status: :ok
        end
      end
    end
  end
end
