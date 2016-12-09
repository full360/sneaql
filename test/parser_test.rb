gem "minitest"
require 'minitest/autorun'

$base_path=File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/base.rb"
require_relative "#{$base_path}/lib/sneaql_lib/core.rb"
require_relative "#{$base_path}/lib/sneaql_lib/parser.rb"
require_relative "#{$base_path}/lib/sneaql_lib/expressions.rb"
require_relative "#{$base_path}/lib/sneaql_lib/recordset.rb"

class TestSneaqlStepParser < Minitest::Test
  def test_parse_statements_from_file_via_initialize
    p = Sneaql::Core::StepParser.new(
      "#{$base_path}/test/fixtures/test-transform/insert.sql",
      expression_handler,
      recordset_manager
    )

    assert_equal(
      4,
      p.statements.length
    )

    assert_equal(
      '/*-execute-*/ create table test(a integer);',
      p.statements[0].strip
    )

    assert_equal(
      '/*-execute-*/ insert into test values (1);',
      p.statements[1].strip
    )

    assert_equal(
      '/*-execute-*/ insert into test values (2);',
      p.statements[2].strip
    )

    assert_equal(
      '/*-test = 3-*/ select sum(a) from test;',
      p.statements[3].strip
    )
  end

  def expression_handler
    Sneaql::Core::ExpressionHandler.new(ENV)
  end

  def recordset_manager
    Sneaql::Core::RecordsetManager.new(expression_handler)
  end

  def parse_error_scenario(file, error_class)
    err = nil
    begin
      p = Sneaql::Core::StepParser.new(
        file,
        expression_handler,
        recordset_manager
      )
    rescue => e
      err = e
    end

    assert_equal(
      error_class,
      err.class,
    )
  end

  def test_no_tags_in_file
    parse_error_scenario(
      "#{$base_path}/test/fixtures/malformed_sql_files/insert_fail_no_tag.sql",
      Sneaql::Exceptions::NoStatementsFoundInFile
    )
  end

  def test_tag_splitter
    p=Sneaql::Core::StepParser.new(
      "#{$base_path}/test/fixtures/test-transform/insert.sql",
      expression_handler,
      recordset_manager
    )

    assert_equal(
      ['execute'],
      p.tag_splitter("/*-execute-*/ select 1;")
    )

    assert_equal(
      ['assign','var','value'],
      p.tag_splitter("/*-assign var value-*/")
    )

    assert_equal(
      ['test','=','0'],
      p.tag_splitter("/*-test = 0-*/ select 0")
    )
  end

  def test_command_at_index
    p = Sneaql::Core::StepParser.new(
      "#{$base_path}/test/fixtures/test-transform/insert.sql",
      expression_handler,
      recordset_manager
    )
    assert(
      {:command=>'execute',:arguments=>[]},
      p.command_at_index(0)
    )

    assert(
      {:command=>'execute',:arguments=>[]},
      p.command_at_index(1)
    )

    assert(
      {:command=>'test',:arguments=>['=','0']},
      p.command_at_index(2)
    )
  end

  def test_validate_arguments
    p = Sneaql::Core::StepParser.new(
      "#{$base_path}/test/fixtures/malformed_sql_files/arguments_all_valid.sql",
      expression_handler,
      recordset_manager
    )

    assert_equal(
      true,
      p.valid_arguments_in_all_statements?
    )

    p = Sneaql::Core::StepParser.new(
      "#{$base_path}/test/fixtures/malformed_sql_files/arguments_invalid.sql",
      expression_handler,
      recordset_manager
    )

    assert_equal(
      false,
      p.valid_arguments_in_all_statements?
    )
  end
end