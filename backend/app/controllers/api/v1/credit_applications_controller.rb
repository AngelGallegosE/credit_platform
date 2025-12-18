module Api
  module V1
    class CreditApplicationsController < ApplicationController
      include Authenticable

      before_action :authorize_admin!, only: [ :destroy ]

      def index
        result = CreditApplication.filtered_and_paginated(
          { country: params[:country], status: params[:status] },
          page: params[:page],
          per_page: 30
        )

        render json: {
          data: result[:data].map { |app| serialize_credit_application(app) },
          pagination: result[:pagination]
        }, status: :ok
      end

      def create
        service = CreateCreditApplicationService.new(credit_application_params.merge(user_id: current_user.id))
        result = service.call

        if result[:success]
          render json: {
            message: "Credit application created successfully",
            credit_application: serialize_credit_application(result[:credit_application])
          }, status: :created
        else
          render json: {
            message: "Credit application could not be created",
            errors: result[:errors]
          }, status: :unprocessable_entity
        end
      end

      def show
        credit_application = CreditApplication.find_by(id: params[:id], country: params[:country])

        if credit_application
          render json: {
            credit_application: credit_application
          }, status: :ok
        else
          render json: {
            message: "Credit application not found"
          }, status: :not_found
        end
      end

      def update
        credit_application = CreditApplication.find_by(id: params[:id], country: params[:country])

        unless credit_application
          return render json: {
            message: "Credit application not found"
          }, status: :not_found
        end

        if credit_application.update(update_params)
          render json: {
            message: "Credit application updated successfully",
            credit_application: serialize_credit_application(credit_application)
          }, status: :ok
        else
          render json: {
            message: "Credit application could not be updated",
            errors: credit_application.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def destroy
        credit_application = CreditApplication.find_by(id: params[:id], country: params[:country])

        if credit_application
          credit_application.destroy
          render json: { message: "Credit application deleted successfully" }, status: :ok
        else
          render json: { message: "Credit application not found" }, status: :not_found
        end
      end

      private

      def credit_application_params
        params.permit(:country, :full_name, :requested_amount, :status, :identity_document)
      end

      def update_params
        params.permit(:status)
      end

      def serialize_credit_application(credit_application)
        {
          id: credit_application.id,
          country: credit_application.country,
          full_name: credit_application.full_name,
          requested_amount: credit_application.requested_amount.to_f,
          status: credit_application.status,
          application_date: Time.current.strftime("%Y-%m-%d"),
          identity_document_url: credit_application.identity_document.attached? ? url_for(credit_application.identity_document) : nil
        }
      end
    end
  end
end
