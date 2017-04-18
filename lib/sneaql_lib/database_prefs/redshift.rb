module Sneaql
  module Core
    # Settings for interaction with Amazon Redshift
    class RedshiftDatabaseManager < Sneaql::Core::DatabaseManager
      Sneaql::Core::RegisterMappedClass.new(
        :database,
        'redshift',
        Sneaql::Core::RedshiftDatabaseManager
      )

      def initialize
        super(
          {
            has_boolean: true,
            autocommit_off_statement: 'set autocommit=off;'
          }
        )
      end
    end
  end
end
