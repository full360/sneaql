gem "minitest"
require 'minitest/autorun'

$base_path=File.expand_path("#{File.dirname(__FILE__)}/../")
require_relative "#{$base_path}/lib/sneaql_lib/expressions.rb"

class TestSneaqlExpressionManager < Minitest::Test

  def test_set_env_vars_via_constructor
    x = Sneaql::Core::ExpressionHandler.new

    assert_equal(
      ENV['HOSTNAME'],
      x.get_environment_variable('HOSTNAME')
    )
  end

  def test_set_and_get_session_variables
    x = Sneaql::Core::ExpressionHandler.new
    [
      {var_name: 'string', var_value: 'string'},
      {var_name: 'number', var_value: 22.5}
    ].each do |v|
      x.set_session_variable(
        v[:var_name],
        v[:var_value]
      )

      assert_equal(
        v[:var_value],
        x.get_session_variable(v[:var_name])
      )
    end
    
    # make sure we can't set an env var using this method
    errored = false
    
    begin
      x.set_session_variable(
        'env_BAD_ENV_VAR',
        0
      )   
    rescue => e
      errored = true
    end
    
    assert_equal(
      true,
      errored
    )
  end

  def test_evaluate_expression
    ENV['sneaql'] = '22'

    x = Sneaql::Core::ExpressionHandler.new
    x.set_session_variable('number', 3)

    assert_equal(
      3,
      x.evaluate_expression(':number')
    )

    assert_equal(
      '22',
      x.evaluate_expression(':env_sneaql')
    )

    assert_equal(
      3,
      x.evaluate_expression('{number}')
    ) #deprecated

    #test changing the variable to another type
    x.set_session_variable('number', '3')

    assert_equal(
      '3',
      x.evaluate_expression(':number')
    )

    assert_equal(
      '3',
      x.evaluate_expression('{number}')
    ) #deprecated
  end

  def test_evaluate_all_expressions
    x = Sneaql::Core::ExpressionHandler.new
    x.set_session_variable('number', 3)
    x.set_session_variable('string', 'wordy')

    assert_equal(
      '3 wordy',
      x.evaluate_all_expressions(':number :string')
    )

    assert_equal(
      '3 wordy',
      x.evaluate_all_expressions('{number} {string}')
    ) #deprecated
  end

  def test_valid_expression_reference
    x = Sneaql::Core::ExpressionHandler.new
    [
      ["'turtle'", true],
      [':turtle', true],
      ['1', true],
      ['1234.56', true],
      ['1,234.56', false],
      ["'hammer@g0g0_#'", true]
    ].each do |t|
      assert_equal(
        t[1],
        x.valid_expression_reference?(t[0])
      )
    end
  end

  def test_compare_expressions
    x = Sneaql::Core::ExpressionHandler.new
    x.set_session_variable('one',1)
    x.set_session_variable('two',2)

    [
      {op1: 1, op: '=', op2: 1, result: true},
      {op1: 1, op: '=', op2: 2, result: false},

      {op1: 1, op: '!=', op2: 1, result: false},
      {op1: 1, op: '!=', op2: 2, result: true},

      {op1: 1, op: '<', op2: 1, result: false},
      {op1: 1, op: '<', op2: 2, result: true},

      {op1: 1, op: '>', op2: 1, result: false},
      {op1: 2, op: '>', op2: 1, result: true},

      {op1: 1, op: '>=', op2: 1, result: true},
      {op1: 2, op: '>=', op2: 1, result: true},
      {op1: 1, op: '>=', op2: 2, result: false},

      {op1: 1, op: '<=', op2: 1, result: true},
      {op1: 2, op: '<=', op2: 1, result: false},
      {op1: 1, op: '<=', op2: 2, result: true},

      {op1: ':one', op: '=', op2: ':one', result: true},
      {op1: ':one', op: '=', op2: 2, result: false},

      {op1: ':one', op: '!=', op2: ':one', result: false},
      {op1: ':one', op: '!=', op2: 2, result: true},

      {op1: ':one', op: '<', op2: ':one', result: false},
      {op1: ':one', op: '<', op2: 2, result: true},

      {op1: ':one', op: '>', op2: ':one', result: false},
      {op1: 2, op: '>', op2: ':one', result: true},

      {op1: ':one', op: '>=', op2: ':one', result: true},
      {op1: 2, op: '>=', op2: ':one', result: true},
      {op1: ':one', op: '>=', op2: 2, result: false},

      {op1: ':one', op: '<=', op2: ':one', result: true},
      {op1: 2, op: '<=', op2: ':one', result: false},
      {op1: ':one', op: '<=', op2: 2, result: true},

      {op1: ':one', op: '=', op2: ':one', result: true},
      {op1: ':one', op: '=', op2: ':two', result: false},

      {op1: ':one', op: '!=', op2: ':one', result: false},
      {op1: ':one', op: '!=', op2: ':two', result: true},

      {op1: ':one', op: '<', op2: ':one', result: false},
      {op1: ':one', op: '<', op2: ':two', result: true},

      {op1: ':one', op: '>', op2: ':one', result: false},
      {op1: ':two', op: '>', op2: ':one', result: true},

      {op1: ':one', op: '>=', op2: ':one', result: true},
      {op1: ':two', op: '>=', op2: ':one', result: true},
      {op1: ':one', op: '>=', op2: ':two', result: false},

      {op1: ':one', op: '<=', op2: ':one', result: true},
      {op1: ':two', op: '<=', op2: ':one', result: false},
      {op1: ':one', op: '<=', op2: ':two', result: true},

      {op1: 'turkey', op: 'like', op2: 'turk', result: false},
      {op1: 'turkey', op: 'like', op2: 'turk_y', result: true},
      {op1: 'turkey', op: 'like', op2: 'turk%', result: true},
      {op1: 'turkey', op: 'like', op2: '%turk%', result: true},

      {op1: 'turkey', op: 'notlike', op2: 'turk', result: true},
      {op1: 'turkey', op: 'notlike', op2: 'turk_y', result: false},
      {op1: 'turkey', op: 'notlike', op2: 'turk%', result: false},
      {op1: 'turkey', op: 'notlike', op2: '%turk%', result: false}

    ].each do |v|
      assert_equal(
        v[:result],
        x.compare_expressions(v[:op], v[:op1], v[:op2])
      )
    end
  end

  def test_valid_session_variable_name
    x = Sneaql::Core::ExpressionHandler.new
    [
      ["varname", true],
      ["'turtle'", false],
      [':turtle', false],
      ['1_chicken', false],
      ['chic%en', false],
      ['env_turtle', false]
    ].each do |t|
      assert_equal(
        t[1],
        x.valid_session_variable_name?(t[0])
      )
    end
  end
  
  def test_filtered_environment_variables
    # tests that the filter works for all supplied variables
    x = Sneaql::Core::ExpressionHandler.new
    ENV.keys.each do |k|
      assert_equal(
        ENV[k],
        x.get_environment_variable(k)
      )
    end
    
    ENV['TEST'] = 'purple'
    ENV['TEST2'] = 'orange'
    ENV['SNEAQL_AVAILABLE_ENV_VARS'] = 'TEST,TEST2'
    
    x = Sneaql::Core::ExpressionHandler.new
    
    assert_equal(
      x.filtered_environment_variables,
      {
        'TEST' => 'purple',
        'TEST2' => 'orange'
      }
    )
    
    ENV.delete('TEST')
    ENV.delete('TEST2')
    ENV.delete('SNEAQL_AVAILABLE_ENV_VARS')
  end
end