gem "minitest"
require 'minitest/autorun'

$base_path=File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/core.rb"
require_relative "#{$base_path}/lib/sneaql_lib/expressions.rb"
require_relative "#{$base_path}/lib/sneaql_lib/recordset.rb"
require_relative "#{$base_path}/lib/sneaql_lib/exceptions.rb"
require_relative "#{$base_path}/test/helpers/sqlite_helper.rb"

class TestSneaqlCoreCommands < Minitest::Test
  def add_table_to_database(conn)
    JDBCHelpers::Execute.new(
      conn,
      "create table test (
        a integer,
        b varchar(15),
        c timestamp,
        d date
      );"
    )

    JDBCHelpers::Execute.new(
      conn,
      "insert into test values(
        12345,
        'chicken',
        '2016-07-01T23:23:23.000',
        '2016-07-01'
      );"
    )
    JDBCHelpers::Execute.new(
      conn,
      "insert into test values(
        12346,
        'turkey',
        '2016-07-01T23:23:23.000',
        '2016-07-01'
      );"
    )
  end

  def test_assign_integer
    jdbc_connection = give_me_an_empty_test_database
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlAssign.new(
      jdbc_connection,
      expression_handler,
      nil,
      nil
    )
    c.action *['var',22]

    assert_equal(
      22,
      expression_handler.get_session_variable('var')
    )

    jdbc_connection.close
  end

  def test_assign_string
    jdbc_connection = give_me_an_empty_test_database
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlAssign.new(
      jdbc_connection,
      expression_handler,
      nil,
      nil
    )

    c.action *['var','abc123']

    assert_equal(
      'abc123',
      expression_handler.get_session_variable('var')
    )

    jdbc_connection.close
  end

  def test_assign_result_integer
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlAssignResult.new(
      jdbc_connection,
      expression_handler,
      nil,
      'select count(*) from test;'
    )

    c.action *['var']

    assert_equal(
      2,
      expression_handler.get_session_variable('var')
    )

    jdbc_connection.close
  end

  def test_assign_result_string
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlAssignResult.new(
      jdbc_connection,
      expression_handler,
      nil,
      "select 'abcdef123456';"
    )

    c.action *['var']

    assert_equal(
      'abcdef123456',
      expression_handler.get_session_variable('var')
    )

    jdbc_connection.close
  end

  def test_execute_update
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new

    c = Sneaql::Core::Commands::SneaqlExecute.new(
      jdbc_connection,
      expression_handler,
      nil,
      "update test set a=1;"
    )

    c.action *[]

    assert_equal(
      2,
      expression_handler.get_session_variable('last_statement_rows_affected')
    )

    jdbc_connection.close
  end

  def test_execute_if
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlExecuteIf.new(
      jdbc_connection,
      expression_handler,
      nil,
      "update test set a=1;"
    )

    c.action *['1','=','1']

    assert_equal(
      2,
      expression_handler.get_session_variable('last_statement_rows_affected')
    )

    jdbc_connection.close
  end

  def run_action(c, *args)
    tmp = nil
    begin
      c.action(*args)
    rescue => e
      tmp = e
    end
    tmp
  end

  def test_sneaql_test_negative
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlTest.new(
      jdbc_connection,
      expression_handler,
      nil,
      'select count(*) from test;'
    )

    r = run_action(c, *['>','2'])

    assert_equal(
      Sneaql::Exceptions::SQLTestExitCondition,
      r.class
    )

    jdbc_connection.close
  end

  def test_sneaql_test_positive
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlTest.new(
      jdbc_connection,
      expression_handler,
      nil,
      'select count(*) from test;'
    )

    r = run_action(c, *['=','2'])

    assert_equal(
      nil,
      r
    )

    jdbc_connection.close
  end

  def test_exit_if_positive
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlExitIf.new(
      jdbc_connection,
      expression_handler,
      nil,
      'select count(*) from test;'
    )

    r = run_action(c, *['2','>','1'])

    assert_equal(
      Sneaql::Exceptions::SQLTestExitCondition,
      r.class
    )

    jdbc_connection.close
  end

  def test_exit_if_negative
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlExitIf.new(
      jdbc_connection,
      expression_handler,
      nil,
      'select count(*) from test;'
    )

    r = run_action(c, *['2','<','1'])

    assert_equal(
      nil,
      r
    )

    jdbc_connection.close
  end

  def test_exit_step_if_positive
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlExitStepIf.new(
      jdbc_connection,
      expression_handler,
      nil,
      'select count(*) from test;'
    )

    r = run_action(c, *['2','=','2'])

    assert_equal(
      r.class,
      Sneaql::Exceptions::SQLTestStepExitCondition,
     )

    jdbc_connection.close
  end

  def test_exit_step_if_negative
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    c = Sneaql::Core::Commands::SneaqlExitStepIf.new(
      jdbc_connection,
      expression_handler,
      nil,
      'select count(*) from test;'
    )

    r = run_action(c, *['2','<','1'])

    assert_equal(
      nil,
      r
    )

    jdbc_connection.close
  end

  def test_class_registration
    assert_equal(
      Sneaql::Core::Commands::SneaqlAssign,
      Sneaql::Core.find_class(:command,'assign')
    )

    assert_equal(
      Sneaql::Core::Commands::SneaqlAssignResult,
      Sneaql::Core.find_class(:command,'assign_result')
    )

    assert_equal(
      Sneaql::Core::Commands::SneaqlExecuteIf,
      Sneaql::Core.find_class(:command,'execute_if')
    )

    assert_equal(
      Sneaql::Core::Commands::SneaqlTest,
      Sneaql::Core.find_class(:command,'test')
    )

    assert_equal(
      Sneaql::Core::Commands::SneaqlExitIf,
      Sneaql::Core.find_class(:command,'exit_if')
    )

    assert_equal(
      Sneaql::Core::Commands::SneaqlExitStepIf,
      Sneaql::Core.find_class(:command,'exit_step_if')
    )
  end

  def test_recordset
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    recordset_manager = Sneaql::Core::RecordsetManager.new(expression_handler)
    c = Sneaql::Core::Commands::SneaqlRecordsetFromQuery.new(
      jdbc_connection,
      expression_handler,
      recordset_manager,
      'select * from test;'
    )

    r = run_action(c, *['rs'])

    target_rs = [
      {"a"=>12345, "b"=>"chicken", "c"=>"2016-07-01T23:23:23.000", "d"=>"2016-07-01"},
      {"a"=>12346, "b"=>"turkey", "c"=>"2016-07-01T23:23:23.000", "d"=>"2016-07-01"}
    ]

    assert_equal(
      target_rs,
      recordset_manager.recordset['rs']
    )
  end

  def test_iterate
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    recordset_manager = Sneaql::Core::RecordsetManager.new(expression_handler)
    recordset_manager.store_recordset(
      'rs',
      [
        {"a"=>12345, "b"=>"chicken", "c"=>"2016-07-01T23:23:23.000", "d"=>"2016-07-01"},
        {"a"=>12346, "b"=>"turkey", "c"=>"2016-07-01T23:23:23.000", "d"=>"2016-07-01"}
      ]
    )
    JDBCHelpers::Execute.new(
      jdbc_connection,
      "create table test2(a integer);"
    )
    c = Sneaql::Core::Commands::SneaqlIterateRecordset.new(
      jdbc_connection,
      expression_handler,
      recordset_manager,
      'insert into test2 values(:rs.a);'
    )

    r = run_action(c, *['rs'])

    sum = JDBCHelpers::SingleValueFromQuery.new(
      jdbc_connection,
      "select sum(a) from test2;"
    ).result

    assert_equal(
      12345 + 12346,
      sum
    )
  end

  def test_iterate_with_filter
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    recordset_manager = Sneaql::Core::RecordsetManager.new(expression_handler)
    recordset_manager.store_recordset(
      'rs',
      [
        {"a"=>12345, "b"=>"chicken", "c"=>"2016-07-01T23:23:23.000", "d"=>"2016-07-01"},
        {"a"=>12346, "b"=>"turkey", "c"=>"2016-07-01T23:23:23.000", "d"=>"2016-07-01"}
      ]
    )
    JDBCHelpers::Execute.new(
      jdbc_connection,
      "create table test2(a integer);"
    )
    c = Sneaql::Core::Commands::SneaqlIterateRecordset.new(
      jdbc_connection,
      expression_handler,
      recordset_manager,
      'insert into test2 values(:rs.a);'
    )

    r = run_action(
      c,
      *['rs', 'include', 'a', '=', 12345, 'include', 'b', '=', 'chicken']
    )

    sum = JDBCHelpers::SingleValueFromQuery.new(
      jdbc_connection,
      "select sum(a) from test2;"
    ).result

    assert_equal(
      12345,
      sum
    )
  end

  def test_rs_directories
    jdbc_connection = give_me_an_empty_test_database
    add_table_to_database(jdbc_connection)
    expression_handler = Sneaql::Core::ExpressionHandler.new
    recordset_manager = Sneaql::Core::RecordsetManager.new(expression_handler)

    c = Sneaql::Core::Commands::SneaqlRecordsetFromDirGlob.new(
      jdbc_connection,
      expression_handler,
      recordset_manager,
      ''
    )

    r = run_action(c, *['rs',"#{$base_path}/test/fixtures/test-transform/*"])

    recordset_manager.recordset['rs'].each do |r|
      assert_equal(
        true,
        File.exists?(r['path_name'])
      )
    end
  end

  def test_argument_validation
    expression_handler = Sneaql::Core::ExpressionHandler.new
    recordset_manager = Sneaql::Core::RecordsetManager.new(expression_handler)
    [
      {test_class: Sneaql::Core::Commands::SneaqlAssign, args: ['turkey',22], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlAssign, args: ['turkey',22.5], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlAssign, args: ['turkey',"'chicken'"], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlAssign, args: ['turkey',':pheasant'], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlAssign, args: ['turkey',':env_HOSTNAME'], is_valid: true},

      {test_class: Sneaql::Core::Commands::SneaqlExecuteIf, args: [':a','=',22], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExecuteIf, args: [':a','=',':a'], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExecuteIf, args: [':a','=',':env_HOSTNAME'], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExecuteIf, args: [':a','=',22.5], is_valid: true},

      {test_class: Sneaql::Core::Commands::SneaqlExitStepIf, args: [':a','=',22], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExitStepIf, args: [':a','=',':a'], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExitStepIf, args: [':a','=',':env_HOSTNAME'], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExitStepIf, args: [':a','=',22.5], is_valid: true},

      {test_class: Sneaql::Core::Commands::SneaqlExitIf, args: [':a','=',22], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExitIf, args: [':a','=',':a'], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExitIf, args: [':a','=',':env_HOSTNAME'], is_valid: true},
      {test_class: Sneaql::Core::Commands::SneaqlExitIf, args: [':a','=',22.5], is_valid: true}
    ].each do |arg_val_test|
      c = arg_val_test[:test_class].new(
        nil,
        expression_handler,
        recordset_manager,
        ''
      )

      assert_equal(
        arg_val_test[:is_valid],
        c.validate_args(arg_val_test[:args])
      )
    end
  end
end