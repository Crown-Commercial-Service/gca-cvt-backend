# frozen_string_literal: true

module CommercialValueTool
  class Contract < ApplicationRecord
    # Adds searching, sorting, filtering, and pagination to {Contract}.
    #
    # Extracts the +.search+ class method and its supporting constants,
    # structs, and private helpers so the model file stays focused on
    # table/column configuration.
    module Searchable
      extend ActiveSupport::Concern

      included do
        # Single source of truth: calculation_completed boolean → status string.
        STATUS_MAP = { true => "completed", false => "in_progress" }.freeze

        # Columns that may be used for sort ordering.
        SORTABLE_COLUMNS = %w[title ocid amount start_date end_date status].freeze
        # Maps logical sort keys to actual SQL column/alias names.
        SORT_COLUMN_MAP = { "status" => Arel.sql("CASE WHEN calculation_completed THEN '#{STATUS_MAP[true]}' ELSE '#{STATUS_MAP[false]}' END") }.freeze
        # @return [String] the default column to sort by
        DEFAULT_SORT_COLUMN = "start_date"
        # @return [String] the default sort direction
        DEFAULT_SORT_DIRECTION = "desc"

        # Lightweight value object for a single contract row.
        ContractData = Struct.new(:record_id, :title, :ocid, :amount, :start_date, :end_date, :calculation_completed, keyword_init: true) do
          # @return [String] 'completed' or 'in_progress'
          def status
            Contract::STATUS_MAP.fetch(calculation_completed)
          end
        end

        # Paginated collection of {ContractData} items with sort metadata.
        SearchResults = Struct.new(:items, :current_page, :total_pages, :limit_value, :total_count, :sort_column, :sort_direction, keyword_init: true) do
          include Enumerable

          # Iterates over the {ContractData} items.
          def each(&) = items.each(&)
        end
      end

      class_methods do
        # Searches, filters, sorts and paginates contracts.
        #
        # @param search [String, nil] free-text search term matched against title and OCID
        # @param sort [String] the column name to sort results by (must be in {SORTABLE_COLUMNS})
        # @param direction [String] sort direction, either "asc" or "desc"
        # @param page [Integer, nil] the page number for Kaminari pagination
        # @param filters [Hash] date-range and value-range filter parameters
        # @return [SearchResults] a paginated, enumerable collection of {ContractData} items
        def search(search: nil, sort: DEFAULT_SORT_COLUMN, direction: DEFAULT_SORT_DIRECTION, page: nil, filters: {})
          sort_column = SORTABLE_COLUMNS.include?(sort) ? sort : DEFAULT_SORT_COLUMN
          sort_direction = %w[asc desc].include?(direction) ? direction : DEFAULT_SORT_DIRECTION

          contracts = latest_per_ocid
          contracts = apply_search(contracts, search)
          contracts = apply_filters(contracts, filters)

          db_column = SORT_COLUMN_MAP.fetch(sort_column, sort_column)
          relation = contracts.order(db_column => sort_direction.to_sym).page(page)

          SearchResults.new(
            items: relation.map { |c| ContractData.new(record_id: c.record_id, title: c.title, ocid: c.ocid, amount: c.amount, start_date: c.start_date, end_date: c.end_date, calculation_completed: c.calculation_completed) },
            current_page: relation.current_page,
            total_pages: relation.total_pages,
            limit_value: relation.limit_value,
            total_count: relation.total_count,
            sort_column: sort_column,
            sort_direction: sort_direction
          )
        end

        private

        # Returns the most recent record for each unique OCID,
        # ordered by +record_inserted_date+ descending.
        #
        # @return [ActiveRecord::Relation] one row per OCID
        def latest_per_ocid
          subquery = unscoped.select("DISTINCT ON (ocid) *").order(:ocid, record_inserted_date: :desc)
          from(subquery, :contracts)
        end

        # Filters a contracts relation by a free-text search term,
        # matching case-insensitively against the title and OCID columns.
        #
        # @param contracts [ActiveRecord::Relation] the base relation to filter
        # @param term [String, nil] the search term; returns the relation unchanged when blank
        # @return [ActiveRecord::Relation] the filtered relation
        def apply_search(contracts, term)
          return contracts if term.blank?

          contracts.where("title ILIKE :term OR ocid ILIKE :term", term: "%#{sanitize_sql_like(term)}%")
        end

        # Narrows a contracts relation using optional date-range and
        # value-range boundaries supplied as filter parameters.
        #
        # @param contracts [ActiveRecord::Relation] the base relation to filter
        # @param filters [Hash] filter boundaries with optional keys
        #   +:start_date_from+, +:start_date_to+, +:end_date_from+,
        #   +:end_date_to+, +:value_min+, +:value_max+ and +:status+
        # @return [ActiveRecord::Relation] the filtered relation
        def apply_filters(contracts, filters)
          contracts = contracts.where(start_date: filters[:start_date_from]..) if filters[:start_date_from]
          contracts = contracts.where(start_date: ..filters[:start_date_to]) if filters[:start_date_to]
          contracts = contracts.where(end_date: filters[:end_date_from]..) if filters[:end_date_from]
          contracts = contracts.where(end_date: ..filters[:end_date_to]) if filters[:end_date_to]
          contracts = contracts.where(amount: filters[:value_min].to_d..) if filters[:value_min]
          contracts = contracts.where(amount: ..filters[:value_max].to_d) if filters[:value_max]
          contracts = apply_status_filter(contracts, filters[:status]) if filters[:status]

          contracts
        end

        # Narrows by the displayed status string, mapping back through
        # {STATUS_MAP} to the underlying +calculation_completed+ boolean.
        # Unknown values are ignored so a malformed query param does
        # not silently empty the table.
        #
        # @param contracts [ActiveRecord::Relation]
        # @param status [String, nil] one of the values in {STATUS_MAP}
        # @return [ActiveRecord::Relation]
        def apply_status_filter(contracts, status)
          boolean = STATUS_MAP.invert[status]
          return contracts if boolean.nil?

          contracts.where(calculation_completed: boolean)
        end
      end
    end
  end
end
