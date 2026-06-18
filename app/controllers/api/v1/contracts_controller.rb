module Api
  module V1
    # Lists and filters contracts. Supports search, sort, date/value filters, pagination.
    # All filter params mirror the existing CVT monolith contracts controller.
    class ContractsController < ApplicationController
      FILTER_PARAM_KEYS = %w[
        start_date_from_day start_date_from_month start_date_from_year
        start_date_to_day start_date_to_month start_date_to_year
        end_date_from_day end_date_from_month end_date_from_year
        end_date_to_day end_date_to_month end_date_to_year
        value_min value_max status
      ].freeze

      ALLOWED_STATUSES = CommercialValueTool::Contract::STATUS_MAP.values.freeze

      def index
        contracts = CommercialValueTool::Contract.search(
          search: params[:search].presence,
          sort: params[:sort],
          direction: params[:direction],
          page: params[:page],
          filters: extract_filter_params
        )

        render json: Api::V1::ContractSerializer.call(contracts)
      end

      private

      def extract_filter_params
        {
          start_date_from: parse_date_params(:start_date_from),
          start_date_to: parse_date_params(:start_date_to),
          end_date_from: parse_date_params(:end_date_from),
          end_date_to: parse_date_params(:end_date_to),
          value_min: params[:value_min]&.delete(",")&.presence,
          value_max: params[:value_max]&.delete(",")&.presence,
          status: (params[:status].presence if ALLOWED_STATUSES.include?(params[:status]))
        }
      end

      def parse_date_params(prefix)
        day   = params[:"#{prefix}_day"].presence
        month = params[:"#{prefix}_month"].presence
        year  = params[:"#{prefix}_year"].presence
        return nil unless day && month && year

        Date.new(year.to_i, month.to_i, day.to_i)
      rescue Date::Error
        nil
      end
    end
  end
end
