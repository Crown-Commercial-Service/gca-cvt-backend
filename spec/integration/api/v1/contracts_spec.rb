require "swagger_helper"

RSpec.describe "api/v1/contracts", type: :request do
  path "/api/v1/contracts" do
    get "List contracts" do
      tags "Contracts"
      produces "application/json"

      parameter name: :search, in: :query, type: :string, required: false,
                description: "Free-text search matched against title and OCID"
      parameter name: :sort, in: :query, type: :string, required: false,
                enum: %w[title ocid amount start_date end_date status],
                description: "Column to sort by"
      parameter name: :direction, in: :query, type: :string, required: false,
                enum: %w[asc desc],
                description: "Sort direction"
      parameter name: :page, in: :query, type: :integer, required: false,
                description: "Page number"
      parameter name: :value_min, in: :query, type: :string, required: false,
                description: "Minimum contract value (accepts comma-formatted numbers, e.g. 1,000)"
      parameter name: :value_max, in: :query, type: :string, required: false,
                description: "Maximum contract value (accepts comma-formatted numbers, e.g. 1,000,000)"
      parameter name: :status, in: :query, type: :string, required: false,
                enum: %w[completed in_progress],
                description: "Contract status derived from calculation_completed"
      parameter name: :start_date_from_day, in: :query, type: :integer, required: false,
                description: "Start date range lower bound — day"
      parameter name: :start_date_from_month, in: :query, type: :integer, required: false,
                description: "Start date range lower bound — month"
      parameter name: :start_date_from_year, in: :query, type: :integer, required: false,
                description: "Start date range lower bound — year"
      parameter name: :start_date_to_day, in: :query, type: :integer, required: false,
                description: "Start date range upper bound — day"
      parameter name: :start_date_to_month, in: :query, type: :integer, required: false,
                description: "Start date range upper bound — month"
      parameter name: :start_date_to_year, in: :query, type: :integer, required: false,
                description: "Start date range upper bound — year"
      parameter name: :end_date_from_day, in: :query, type: :integer, required: false,
                description: "End date range lower bound — day"
      parameter name: :end_date_from_month, in: :query, type: :integer, required: false,
                description: "End date range lower bound — month"
      parameter name: :end_date_from_year, in: :query, type: :integer, required: false,
                description: "End date range lower bound — year"
      parameter name: :end_date_to_day, in: :query, type: :integer, required: false,
                description: "End date range upper bound — day"
      parameter name: :end_date_to_month, in: :query, type: :integer, required: false,
                description: "End date range upper bound — month"
      parameter name: :end_date_to_year, in: :query, type: :integer, required: false,
                description: "End date range upper bound — year"

      response "200", "contracts returned" do
        schema type: :object,
               required: %w[data meta],
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     required: %w[record_id title ocid status],
                     properties: {
                       record_id: { type: :integer },
                       title: { type: :string },
                       ocid: { type: :string },
                       amount: { type: :string, nullable: true },
                       start_date: { type: :string, format: :date, nullable: true },
                       end_date: { type: :string, format: :date, nullable: true },
                       status: { type: :string, enum: %w[completed in_progress] }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   required: %w[page total_pages total_count per_page sort_column sort_direction],
                   properties: {
                     page: { type: :integer },
                     total_pages: { type: :integer },
                     total_count: { type: :integer },
                     per_page: { type: :integer },
                     sort_column: { type: :string },
                     sort_direction: { type: :string }
                   }
                 }
               }

        before { create(:contract) }

        run_test!
      end

      response "200", "contracts filtered by search term" do
        schema type: :object,
               required: %w[data meta],
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     required: %w[record_id title ocid status],
                     properties: {
                       record_id: { type: :integer },
                       title: { type: :string },
                       ocid: { type: :string },
                       amount: { type: :string, nullable: true },
                       start_date: { type: :string, format: :date, nullable: true },
                       end_date: { type: :string, format: :date, nullable: true },
                       status: { type: :string, enum: %w[completed in_progress] }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   required: %w[page total_pages total_count per_page sort_column sort_direction],
                   properties: {
                     page: { type: :integer },
                     total_pages: { type: :integer },
                     total_count: { type: :integer },
                     per_page: { type: :integer },
                     sort_column: { type: :string },
                     sort_direction: { type: :string }
                   }
                 }
               }

        let(:search) { "Test" }
        before { create(:contract, title: "Test Contract Alpha") }

        run_test!
      end

      response "200", "contracts filtered by status" do
        schema type: :object,
               required: %w[data meta],
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     required: %w[record_id title ocid status],
                     properties: {
                       record_id: { type: :integer },
                       title: { type: :string },
                       ocid: { type: :string },
                       amount: { type: :string, nullable: true },
                       start_date: { type: :string, format: :date, nullable: true },
                       end_date: { type: :string, format: :date, nullable: true },
                       status: { type: :string, enum: %w[completed in_progress] }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   required: %w[page total_pages total_count per_page sort_column sort_direction],
                   properties: {
                     page: { type: :integer },
                     total_pages: { type: :integer },
                     total_count: { type: :integer },
                     per_page: { type: :integer },
                     sort_column: { type: :string },
                     sort_direction: { type: :string }
                   }
                 }
               }

        let(:status) { "completed" }
        before { create(:contract, :completed) }

        run_test!
      end
    end
  end
end
