gem "minitest"
require 'minitest/autorun'

$base_path = File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/core.rb"
require_relative "#{$base_path}/lib/sneaql_lib/expressions.rb"
require_relative "#{$base_path}/lib/sneaql_lib/recordset.rb"
require_relative "#{$base_path}/test/helpers/sqlite_helper.rb"

class TestRecordsetManager < Minitest::Test
  def add_table_to_database(conn)
    JDBCHelpers::Execute.new(
      conn,
      "create table test(a integer, b varchar(15), c timestamp, d date);"
    )

    JDBCHelpers::Execute.new(
      conn,
      "insert into test values(12345,'chicken','2016-07-01T23:23:23.000','2016-07-01');"
    )

    JDBCHelpers::Execute.new(
      conn,
      "insert into test values(12346,'turkey','2016-07-01T23:23:23.000','2016-07-01');"
    )
  end

  def test_store_recordset
    expression_handler = Sneaql::Core::ExpressionHandler.new
    rs = Sneaql::Core::RecordsetManager.new(expression_handler)

    test_rs = [
      {'a' => 2, 'b' => '20151201'},
      {'a' => 3, 'b' => '20151201'},
      {'a' => 2, 'b' => '20160303'}
    ]

    rs.store_recordset('rs',test_rs)

    assert_equal(
      test_rs,
      rs.recordset['rs']
    )
  end

  def test_remove_recordset
    expression_handler = Sneaql::Core::ExpressionHandler.new
    rs = Sneaql::Core::RecordsetManager.new(expression_handler)

    test_rs = [
      {'a' => 2, 'b' => '20151201'},
      {'a' => 3, 'b' => '20151201'},
      {'a' => 2, 'b' => '20160303'}
    ]

    rs.store_recordset('rs',test_rs)

    assert_equal(
      test_rs,
      rs.recordset['rs']
    )
    
    rs.remove_recordset('rs')
    
    assert_equal(
      false,
      rs.recordset.has_key?('rs')
    )
  end

  def test_empty_recordset
    expression_handler = Sneaql::Core::ExpressionHandler.new
    rs = Sneaql::Core::RecordsetManager.new(expression_handler)

    test_rs = []

    rs.store_recordset('rs',test_rs)

    assert_equal(
      test_rs,
      rs.recordset['rs']
    )
  end
   
  def test_parse_expression
    expression_handler = Sneaql::Core::ExpressionHandler.new
    rs = Sneaql::Core::RecordsetManager.new(expression_handler)

    test_rs = [
      {'a' => 2, 'b' => '20151201'},
      {'a' => 3, 'b' => '20151201'},
      {'a' => 2, 'b' => '20160303'}
    ]

    rs.store_recordset('rs', test_rs)

    c = "rs include a = 2 exclude b like '2016%'".split
    t = rs.parse_recordset_expression(c)
    assert_equal(
      t,
      [
        {
          :condition=>"include",
          :field=>"a",
          :operator=>"=",
          :expression=>"2"
        },
        {
          :condition=>"exclude",
          :field=>"b",
          :operator=>"like",
          :expression=>"'2016%'"
        }
      ]
    )

    res = []
    rs.recordset['rs'].each do |r|
      res << rs.evaluate_expression_against_record(r, t)
    end

    assert_equal(
      [true, false, false],
      res
    )

  end
end
