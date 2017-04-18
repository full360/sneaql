module Sneaql
  module Core
    # returns the database type based upon the jdbc url
    # @param [String]
    def self.database_type(jdbc_url)
      Sneaql::Core.class_map[:database].each do |d|
        return d[:text] if jdbc_url.match(d[:text])
      end
    end

    # Manages preferences for a specific RDBMS implementation.
    class DatabaseManager
      attr_reader(
        :has_boolean,
        :autocommit_off_statement,
        :supports_transactions,
        :supports_table_locking,
        :begin_statement,
        :commit_statement,
        :rollback_statement
      )

      # @param [Hash] options values to override defaults
      def initialize(options = {})
        @has_boolean = options.fetch(:has_boolean, default_has_boolean)
        @autocommit_off_statement = options.fetch(:autocommit_off_statement, default_autocommit_off_statement)
        @supports_transactions = options.fetch(:supports_transactions, default_supports_transactions)
        @supports_table_locking = options.fetch(:supports_table_locking, default_supports_table_locking)
        @begin_statement = options.fetch(:begin_statement, default_begin_statement)
        @commit_statement = options.fetch(:commit_statement, default_commit_statement)
        @rollback_statement = options.fetch(:rollback_statement, default_rollback_statement)
      end

      # @return [Boolean]
      def default_has_boolean
        false
      end

      # @return [String]
      def default_autocommit_off_statement
        nil
      end

      # @return [Boolean]
      def default_supports_transactions
        true
      end

      # @return [Boolean]
      def default_supports_table_locking
        false
      end

      # @return [String] begin statement
      def default_begin_statement
        "begin;"
      end

      # @return [String] commit statement
      def default_commit_statement
        "commit;"
      end

      # @return [String] rollback statement
      def default_rollback_statement
        "rollback;"
      end

      # @param [String] table_name
      # @return [String] rollback statement
      def lock_table_statement(table_name)
        "lock table #{table_name};"
      end
    end
  end
end

# Require all tested RDBMS
Dir.glob("#{File.dirname(__FILE__)}/database_prefs/*.rb").each { |f| require File.expand_path(f) }