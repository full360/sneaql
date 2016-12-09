require 'jdbc_helpers'

require_relative 'sqlite-jdbc-3.8.11.2.jar'
java_import 'org.sqlite.JDBC'

def give_me_an_empty_test_database
  File.delete('memory') if File.exists? 'memory'
  conn = JDBCHelpers::ConnectionFactory.new(
    'jdbc:sqlite:memory',
    '',
    ''
  ).connection
  return conn
end

def give_me_the_current_database
  conn = JDBCHelpers::ConnectionFactory.new('jdbc:sqlite:memory','','').connection
  return conn
end