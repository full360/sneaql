gem "minitest"
require 'minitest/autorun'

$base_path = File.expand_path("#{File.dirname(__FILE__)}/../")
require_relative "#{$base_path}/test/helpers/sqlite_helper.rb"
require_relative "#{$base_path}/lib/sneaql.rb"

class TestSneaqlTransform < Minitest::Test
  def test_transform_end_to_end
    File.delete('memory') if File.exists? 'memory'
    
    t = Sneaql::Transform.new({  
      transform_name: 'test-transform',
      repo_base_dir: "#{$base_path}/test/fixtures/test-transform",
      repo_type: 'local', #could be 'http','local_file'
      database: 'sqlite', #could be 'vertica','sqlite'
      jdbc_url: 'jdbc:sqlite:memory',
      db_user: '',
      db_pass: '',
      step_metadata_manager_type: 'local_file',
      step_metadata_file_path: "#{$base_path}/test/fixtures/test-transform/steps.json",
      run: true
    })
    
    assert_equal 0, t.exit_code 
    assert_equal 4, t.current_step
    assert_equal 2, t.current_statement #exit_step_if in da haus!
  end
end