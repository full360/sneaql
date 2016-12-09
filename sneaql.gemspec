Gem::Specification.new do |s|
  s.name        = 'sneaql'
  s.version     = '0.0.2'
  s.date        = '2016-07-01'
  s.summary     = "sneaql language core"
  s.description = "provides the base classes required to run and extend sneaql"
  s.authors     = ["jeremy winters"]
  s.email       = 'jeremy.winters@full360.com'
  s.files       = ["lib/sneaql.rb"]
  
  Dir.glob('lib/sneaql_lib/*.rb').each {|f| s.files << f; puts f}
  Dir.glob('lib/sneaql_lib/database_prefs/*.rb').each {|f| s.files << f; puts f}
  
  s.homepage    = 'https://www.full360.com'
  s.license     = 'MIT'
  s.platform = 'java'
  
  s.add_runtime_dependency 'logger','>=1.2.8'
  s.add_development_dependency 'minitest','>=5.9.0'
  
  s.add_runtime_dependency "jdbc_helpers",'>=0.0.2'
  s.add_runtime_dependency "zip",'>=0.9'
  s.required_ruby_version = '>= 2.0' 
end
