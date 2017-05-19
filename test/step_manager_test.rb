gem "minitest"
require 'minitest/autorun'
require 'jdbc_helpers'
require 'json'

$base_path = File.expand_path("#{File.dirname(__FILE__)}/../")

require_relative "#{$base_path}/lib/sneaql_lib/base.rb"
require_relative "#{$base_path}/lib/sneaql_lib/step_manager.rb"
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
end