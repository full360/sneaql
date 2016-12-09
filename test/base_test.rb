gem 'minitest'
require 'minitest/autorun'

# using a global variable because this is only a test
$base_path = File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/base.rb"
require_relative "#{$base_path}/lib/sneaql_lib/expressions.rb"
require_relative "#{$base_path}/lib/sneaql_lib/recordset.rb"

# this gives the sneaql command test something to change
$test_sneaql_base_command_value = nil

# test initialize for sneaql command
class TestSneaqlBaseCommand < Sneaql::Core::SneaqlCommand
  Sneaql::Core::RegisterMappedClass.new(
    :test_base_command,
    'base',
    TestSneaqlBaseCommand
  )

  def action(a)
    $test_sneaql_base_command_value = [
      a,
      @jdbc_connection,
      @expression_handler,
      @recordset_manager,
      @statement
    ]
  end

  def arg_definition
    [:expression, :operator, :recordset, :variable]
  end
end

# test sneaql command class
class TestBaseCommand < Minitest::Test
  def test_base_command
    d = TestSneaqlBaseCommand.new(
      'jdbc',
      'expression',
      'recordset',
      'statement'
    )
    d.action(*['a'])
    assert_equal(
      $test_sneaql_base_command_value,
      ['a', 'jdbc', 'expression', 'recordset', 'statement']
    )
  end

  def test_argument_validators
    d = TestSneaqlBaseCommand.new(
      'jdbc',
      Sneaql::Core::ExpressionHandler.new(ENV),
      Sneaql::Core::RecordsetManager.new(
        Sneaql::Core::ExpressionHandler.new(ENV)
      ),
      'statement'
    )

    # these methods are for granular testing of args
    # use them when creating your own validate_args
    assert_equal(true, d.valid_variable?('a'))
    assert_equal(false, d.valid_variable?(':a'))
    assert_equal(true, d.valid_operator?('>'))
    assert_equal(false, d.valid_operator?('%'))
    assert_equal(true, d.valid_expression?(':a'))
    assert_equal(true, d.valid_expression?(':env_HOSTNAME'))
    assert_equal(true, d.valid_expression?(22))
    assert_equal(false, d.valid_expression?('>'))
    assert_equal(true, d.valid_recordset?('turkey'))
    assert_equal(false, d.valid_recordset?(':turkey'))

    #insures that args can be tested as a whole
    assert_equal(true, d.validate_args([':a','>','turkey','quail']))
  end
end

# test initialize for repo manager
class TestSneaqlRepoManager < Sneaql::Core::RepoDownloadManager
  Sneaql::Core::RegisterMappedClass.new(
    :repo_manager,
    'base',
    TestSneaqlRepoManager
  )
end

# test manage_repo
class TestSneaqlRepoManager2 < Sneaql::Core::RepoDownloadManager
  Sneaql::Core::RegisterMappedClass.new(
    :repo_manager,
    'base2',
    TestSneaqlRepoManager2
  )

  def manage_repo
    @repo_base_dir = @params[:repo_base_dir]
  end
end

# perform the tests on repo manager
class TestSneaqlBaseRepoManager < Minitest::Test
  def test_test_sneaql_repo_manager
    t = TestSneaqlRepoManager.new(
      {
        repo_base_dir: "#{$base_path}/test/tmp/path",
        transform_name: 'test-transform'
      }
    )

    assert_equal(
      t.repo_base_dir,
      "#{$base_path}/test/tmp/path/test-transform"
    )
  end

  def test_test_sneaql_repo_manager2
    t = TestSneaqlRepoManager2.new(
      {
        repo_base_dir: "#{$base_path}/test/tmp/path",
        transform_name: 'test-transform'
      }
    )

    assert_equal(
      t.repo_base_dir,
      "#{$base_path}/test/tmp/path"
    )
  end
end

class TestSneaqlBase < Minitest::Test
  def test_class_mapping
    #one monolithic test because state is important here due to class variables
    #lower level calls to test class registration support methods
    Sneaql::Core.insure_type_exists(:first_type)
    Sneaql::Core.add_mapped_class(
      :first_type,
      mc={text: 'first_key' , mapped_class: String}
    )

    assert_equal(
      Sneaql::Core.find_class(:first_type,'first_key'),
      String
    )

    #add another type
    Sneaql::Core::RegisterMappedClass.new(
      :second_type,
      'first_key',
      Integer
    )

    assert(Sneaql::Core.class_map.keys.include?(:second_type))

    assert_equal(
      Sneaql::Core.find_class(:second_type,'first_key'),
      Integer
    )

    #and another value to that type
    Sneaql::Core::RegisterMappedClass.new(
      :second_type,
      'second_key',
      Float
    )

    #double check all of them
    assert_equal(
      Sneaql::Core.find_class(:second_type,'second_key'),
      Float
    )

    assert_equal(
      Sneaql::Core.find_class(:second_type,'first_key'),
      Integer
    )

    assert_equal(
      Sneaql::Core.find_class(:first_type,'first_key'),
      String
    )
  end
end
