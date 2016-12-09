gem "minitest"
require 'minitest/autorun'
require 'jdbc_helpers'
require 'json'

$base_path = File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/base.rb"
require_relative "#{$base_path}/lib/sneaql_lib/step_manager.rb"
require_relative "#{$base_path}/lib/sneaql_lib/database_manager.rb"
require_relative "#{$base_path}/lib/sneaql_lib/standard_db_objects.rb"
require_relative "#{$base_path}/test/helpers/sqlite_helper.rb"

class TestSneaqlStepManager < Minitest::Test
  
  def test_that_file_based_manager_was_added
    assert_equal(
      Sneaql::StepManagers::JSONFileStepManager,
      Sneaql::Core.find_class(
        :step_metadata_manager,
        'local_file'
      )
    )
  end
  
  def test_parsing_of_json_based_metadata_file
    target_array = [
      {:step_number=>1, :step_file=>"begin.sql"},
      {:step_number=>2, :step_file=>"insert.sql"},
      {:step_number=>3, :step_file=>"records.sql"},
      {:step_number=>4, :step_file=>"commit.sql"}
    ]
    s = Sneaql::Core.find_class(:step_metadata_manager, 'local_file').new(
      {step_metadata_file_path: "#{$base_path}/test/fixtures/test-transform/steps.json"}
    )
    
    assert_equal(
      target_array,
      s.steps
    )
  end
  
  def test_table_based_manager
    db = give_me_an_empty_test_database
    db_manager = Sneaql::Core::SqliteDatabaseManager.new
    t = Sneaql::Standard::DBObjectCreator.new(
      db,
      db_manager
    )
    
    t.create_transform_steps_table('test')
    
    s = JSON.parse(
      File.read(
        "#{$base_path}/test/fixtures/test-transform/steps.json"
      )
    )
    
    s.each do |step|
      JDBCHelpers::Execute.new(
        db,
        %{insert into test
        (
          transform_name,
          transform_step,
          sql_file_path_in_repo,
          is_active,
          is_precondition,
          updated_ts
        )
        values
        (
          'test',
          #{step['step_number']},
          '#{step['step_file']}',
          #{if db_manager.has_boolean then 'true' else 1 end},
          #{if db_manager.has_boolean then 'false' else 0 end},
          current_timestamp
        );}
      )
    end
    
    tm = Sneaql::StepManagers::TransformStepTableManager.new(
      {
        transform_name: 'test',
        transform_steps_table: 'test',
        jdbc_url: 'jdbc:sqlite:memory',
        db_user: '',
        db_pass: '',
        database_manager: Sneaql::Core::SqliteDatabaseManager.new
      }
    )
    
    tm.manage_steps
    
    target_array = [
      {:step_number=>1, :step_file=>"begin.sql"},
      {:step_number=>2, :step_file=>"insert.sql"},
      {:step_number=>3, :step_file=>"records.sql"},
      {:step_number=>4, :step_file=>"commit.sql"}
    ]
    
    assert_equal(
      target_array,
      tm.steps.sort_by { |h| h['step_number']}
    )
  end
  
end