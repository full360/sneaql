gem "minitest"
require 'minitest/autorun'

$base_path=File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/core.rb"
require_relative "#{$base_path}/lib/sneaql_lib/database_manager.rb"
require_relative "#{$base_path}/test/helpers/sqlite_helper.rb"

class DatabaseManagerTest < Minitest::Test
  def test_database_type()
    assert_equal(
      'redshift',
      Sneaql::Core.database_type(
        'jdbc:redshift:server:5439/dbname'
      )
    )
    
    assert_equal(
      'vertica',
      Sneaql::Core.database_type(
        'jdbc:vertica:server:5433/dbname'
      )
    )
    
    assert_equal(
      'sqlite',
      Sneaql::Core.database_type(
        'jdbc:sqlite'
      )
    )
  end
  
  def test_database_manager
    d = Sneaql::Core::DatabaseManager.new(
      has_boolean: true,
      autocommit_off_statement: 'this statement',
      supports_transactions: false
    )

    assert_equal(
      true,
      d.has_boolean
    )

    assert_equal(
      'this statement',
      d.autocommit_off_statement
    )

    assert_equal(
      false,
      d.supports_transactions
    )
  end

  def test_vertica_manager
    v = Sneaql::Core::VerticaDatabaseManager.new

    assert_equal(
      true,
      v.has_boolean
    )

    assert_equal(
      'set session autocommit to off;',
      v.autocommit_off_statement
    )

    assert_equal(
      true,
      v.supports_transactions
    )
  end

  def test_sqlite_manager
    s = Sneaql::Core::SqliteDatabaseManager.new

    assert_equal(
      false,
      s.has_boolean
    )

    assert_equal(
      nil,
      s.autocommit_off_statement
    )

    assert_equal(
      true,
      s.supports_transactions
    )
  end
  
  def test_redshift_manager
    v = Sneaql::Core::RedshiftDatabaseManager.new

    assert_equal(
      true,
      v.has_boolean
    )

    assert_equal(
      'set autocommit=off;',
      v.autocommit_off_statement
    )

    assert_equal(
      true,
      v.supports_transactions
    )
  end
  
  def test_find_class
    assert_equal(
      Sneaql::Core::SqliteDatabaseManager,
      Sneaql::Core.find_class(:database, 'sqlite')
    )

    assert_equal(
      Sneaql::Core::VerticaDatabaseManager,
      Sneaql::Core.find_class(:database, 'vertica')
    )
    
    assert_equal(
      Sneaql::Core::RedshiftDatabaseManager,
      Sneaql::Core.find_class(:database, 'redshift')
    )
  end
end