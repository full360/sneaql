gem "minitest"
require 'minitest/autorun'

$base_path = File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/core.rb"
require_relative "#{$base_path}/lib/sneaql_lib/database_manager.rb"
require_relative "#{$base_path}/lib/sneaql_lib/standard_db_objects.rb"
require_relative "#{$base_path}/test/helpers/sqlite_helper.rb"

class TestStandardDBObjects < Minitest::Test
  def test_initialize
    t = Sneaql::Standard::DBObjectCreator.new(
      give_me_an_empty_test_database,
      Sneaql::Core::SqliteDatabaseManager.new
    )

    assert_equal(
      Sneaql::Standard::DBObjectCreator,
      t.class
    )

    assert_equal(
      Java::OrgSqlite::SQLiteConnection,
      t.jdbc_connection.class
    )
  end

  def test_coerce_boolean
    t = Sneaql::Standard::DBObjectCreator.new(
      nil,
      Sneaql::Core::SqliteDatabaseManager.new
    )
    
    assert_equal(0, t.coerce_boolean(false))
    assert_equal(1, t.coerce_boolean(true))
    
    t = Sneaql::Standard::DBObjectCreator.new(
      nil,
      Sneaql::Core::VerticaDatabaseManager.new
    )
    
    assert_equal(false, t.coerce_boolean(false))
    assert_equal(true, t.coerce_boolean(true))
  end

  def test_transforms_table_create_statement
    db = give_me_an_empty_test_database
    t = Sneaql::Standard::DBObjectCreator.new(
      db,
      Sneaql::Core::SqliteDatabaseManager.new
    )

    assert_equal(
      t.transforms_table_create_statement('test'),
      %{create table if not exists test
          (
          	transform_name varchar(255) not null
          	,sql_repository varchar(255)
          	,sql_repository_branch varchar(255)
          	,is_active smallint
          	,notify_on_success smallint
          	,notify_on_non_precondition_failure smallint
          	,notify_on_precondition_failure smallint
          	,updated_ts timestamp
          );}
    )

    assert_equal(
      true,
      t.create_transforms_table('test')
    )

    assert_equal(
      true,
      t.recreate_transforms_table('test')
    )

    JDBCHelpers::Execute.new(
      db,
      "insert into test values('test','http://repo','develop',1,1,1,1,'2016-08-01T00:00:00');"
    )

    ret = JDBCHelpers::QueryResultsToArray.new(
      db,
      "select * from test;"
    ).results

    target_row = {
      "transform_name"=>"test",
      "sql_repository"=>"http://repo",
      "sql_repository_branch"=>"develop",
      "is_active"=>1,
      "notify_on_success"=>1,
      "notify_on_non_precondition_failure"=>1,
      "notify_on_precondition_failure"=>1,
      "updated_ts"=>"2016-08-01T00:00:00"
    }

    assert_equal(
      target_row,
      ret[0]
    )
  end

  def test_transform_steps_table_create_statement
    db = give_me_an_empty_test_database
    t = Sneaql::Standard::DBObjectCreator.new(
      db,
      Sneaql::Core::SqliteDatabaseManager.new
    )

    assert_equal(
      %{create table if not exists test
          (
          	transform_name varchar(255) not null
          	,transform_step integer not null
          	,sql_file_path_in_repo varchar(1024)
          	,is_active smallint
          	,is_precondition smallint
          	,updated_ts timestamp
          );},
      t.transform_steps_table_create_statement('test')
    )

    assert_equal(
      true,
      t.create_transform_steps_table('test')
    )

    assert_equal(
      true,
      t.recreate_transform_steps_table('test')
    )

    JDBCHelpers::Execute.new(
      db,
      "insert into test values('test',1,'file/path',1,1,'2016-08-01T00:00:00');"
    )

    ret = JDBCHelpers::QueryResultsToArray.new(
      db,
      "select * from test;"
    ).results

    target_row = {
      "transform_name"=>"test",
      "transform_step"=>1,
      "sql_file_path_in_repo"=>"file/path",
      "is_active"=>1,
      "is_precondition"=>1,
      "updated_ts"=>"2016-08-01T00:00:00"
    }

    assert_equal(
      target_row,
      ret[0]
    )
  end

  def test_transform_lock_table_create_statement
    db = give_me_an_empty_test_database
    t = Sneaql::Standard::DBObjectCreator.new(
      db,
      Sneaql::Core::SqliteDatabaseManager.new
    )

    assert_equal(
      %{create table if not exists test
          (
          	transform_lock_id bigint
          	,transform_name varchar(255)
          	,transform_lock_time timestamp
          );},
      t.transform_lock_table_create_statement('test')
    )

    assert_equal(
      true,
      t.create_transform_lock_table('test')
    )

    assert_equal(
      true,
      t.recreate_transform_lock_table('test')
    )

    JDBCHelpers::Execute.new(
      db,
      "insert into test values(20160711,'test','2016-08-01T00:00:00');"
    )

    ret = JDBCHelpers::QueryResultsToArray.new(
      db,
      "select * from test;"
    ).results

    target_row = {
      "transform_lock_id"=>20160711,
      "transform_name"=>"test",
      "transform_lock_time"=>"2016-08-01T00:00:00"
    }

    assert_equal(
      target_row,
      ret[0]
    )
  end

  def test_transform_log_table_create_statement
    db = give_me_an_empty_test_database
    t = Sneaql::Standard::DBObjectCreator.new(
      db,
      Sneaql::Core::SqliteDatabaseManager.new
    )

    puts t.transform_log_table_create_statement('test')

    assert_equal(
      %{create table if not exists test
          (
          	transform_run_id bigint
          	,transform_lock_id bigint
          	,transform_name varchar(255)
          	,transform_step integer
          	,transform_statement integer
          	,all_steps_complete smallint
          	,failed_in_precondition smallint
          	,message varchar(65000)
          	,transform_start_time timestamp
          	,transform_end_time timestamp
          );},
      t.transform_log_table_create_statement('test')
    )

    assert_equal(
      true,
      t.create_transform_log_table('test')
    )

    assert_equal(
      true,
      t.recreate_transform_log_table('test')
    )

    JDBCHelpers::Execute.new(
      db,
      "insert into test values (
        20160711,
        20160711,
        'test',
        1,
        1,
        1,
        0,
        'message',
        '2016-08-01T00:00:00',
        '2016-08-01T00:00:00'
      );"
    )

    ret = JDBCHelpers::QueryResultsToArray.new(
      db,
      "select * from test;"
    ).results

    target_row = {
      "transform_run_id" => 20160711,
      "transform_lock_id" => 20160711,
      "transform_name" => "test",
      "transform_step" => 1,
      "transform_statement" => 1,
      "all_steps_complete" => 1,
      "failed_in_precondition" => 0,
      "message" => "message",
      "transform_start_time" => "2016-08-01T00:00:00",
      "transform_end_time" => "2016-08-01T00:00:00"
    }

    assert_equal(
      target_row,
      ret[0]
    )
  end
end