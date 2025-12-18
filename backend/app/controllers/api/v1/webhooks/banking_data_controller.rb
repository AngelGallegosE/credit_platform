module Api
  module V1
    module Webhooks
      class BankingDataController < ApplicationController
        def create
          service = ProcessBankingDataWebhookService.new(webhook_params)
          result = service.call

          if result[:success]
            render json: {
              message: "Banking data processed successfully",
              credit_application_id: result[:credit_application_id]
            }, status: :ok
          else
            render json: {
              message: "Failed to process banking data",
              errors: result[:errors]
            }, status: :unprocessable_entity
          end
        end

        private

        def webhook_params
          params.permit!
        end
      end
    end
  end
end
