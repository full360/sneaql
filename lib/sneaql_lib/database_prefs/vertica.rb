module Sneaql
  module Core
    # Settings for interacting with HP Vertica
    class VerticaDatabaseManager < Sneaql::Core::DatabaseManager
      Sneaql::Core::RegisterMappedClass.new(
        :database,
        'vertica',
        Sneaql::Core::VerticaDatabaseManager
      )

      def initialize
        super(
          {
            has_boolean: true,
            autocommit_off_statement: 'set session autocommit to off;'
          }
        )
      end
    end
  end
end
