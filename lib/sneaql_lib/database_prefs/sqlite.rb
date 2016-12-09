module Sneaql
  module Core
    # Settings for interacting with SQLite
    class SqliteDatabaseManager < Sneaql::Core::DatabaseManager
      Sneaql::Core::RegisterMappedClass.new(
        :database,
        'sqlite',
        Sneaql::Core::SqliteDatabaseManager
      ) 
    end
  end
end