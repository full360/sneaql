gem 'minitest'
require 'minitest/autorun'

# using a global variable because this is only a test
$base_path = File.expand_path("#{File.dirname(__FILE__)}/../../") unless $base_path
ENV['SNEAQL_DISABLE_SQL_INJECTION_CHECK']="TEST" unless ENV['SNEAQL_DISABLE_SQL_INJECTION_CHECK']
