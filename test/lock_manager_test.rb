gem "minitest"
require 'minitest/autorun'

$base_path=File.expand_path("#{File.dirname(__FILE__)}/../")
require_relative "#{$base_path}/lib/sneaql_lib/core.rb"
require_relative "#{$base_path}/lib/sneaql_lib/database_manager.rb"
require_relative "#{$base_path}/lib/sneaql_lib/lock_manager.rb"
require_relative "#{$base_path}/test/helpers/sqlite_helper.rb"

class TestRecordsetManager < Minitest::Test
  def add_lock_table_to_database(conn)
    JDBCHelpers::Execute.new(
      conn,
      %{create table if not exists transform_lock
        (
        	transform_lock_id bigint
        	,transform_name varchar(255)
        	,transform_lock_time timestamp
        );}
    )
  end

  def test_remove_lock
    jdbc_connection = give_me_an_empty_test_database
    add_lock_table_to_database(jdbc_connection)
    lock_manager = Sneaql::Core::TransformLockManager.new(
      {
        transform_name: 'test',
        transform_lock_id: 12345,
        transform_lock_table: 'transform_lock',
        jdbc_url: 'jdbc:sqlite:memory',
        db_user: '',
        db_pass: '',
        database: 'sqlite'
      }
    )

    assert_equal true, lock_manager.acquire_lock
    assert_equal true, lock_manager.remove_lock
    
    lock_manager = Sneaql::Core::TransformLockManager.new(
      {
        transform_name: 'test',
        transform_lock_id: 12346,
        transform_lock_table: 'transform_lock',
        jdbc_url: 'jdbc:sqlite:memory',
        db_user: '',
        db_pass: '',
        database: 'sqlite'
      }
    )

    assert_equal true, lock_manager.acquire_lock
  end
end