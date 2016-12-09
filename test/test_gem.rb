require 'sneaql'

# not an official part of the test suite
# this tests the actual gem installed locally
$base_path = File.expand_path("#{File.dirname(__FILE__)}/../")
#load up a sqlite database and delete the db if it's in the path
require_relative 'helpers/sqlite_helper.rb'

File.delete('memory') if File.exists? 'memory'

t = Sneaql::Transform.new(
  {  
    transform_name: 'test-transform',
    repo_base_dir: "#{$base_path}/test/fixtures/test-transform",
    repo_type: 'local',
    database: 'sqlite',
    jdbc_url: 'jdbc:sqlite:memory',
    db_user: '',
    db_pass: '',
    step_metadata_manager_type: 'local_file',
    step_metadata_file_path: "#{$base_path}/test/fixtures/test-transform/steps.json"
  }
)

t.run