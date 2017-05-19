Gem::Specification.new do |s|
  s.name        = 'sneaql'
  s.version     = '0.0.16pre'
  s.date        = '2017-05-19'
  s.summary     = "sneaql language core"
  s.description = "provides the base classes required to run and extend sneaql"
  s.authors     = ["jeremy winters"]
  s.email       = 'jeremy.winters@full360.com'
  s.files       = ["lib/sneaql.rb"]
  s.executables << 'sneaql'
  
  Dir.glob('lib/sneaql_lib/*.rb').each {|f| s.files << f; puts f}
  Dir.glob('lib/sneaql_lib/database_prefs/*.rb').each {|f| s.files << f; puts f}
  
  s.homepage    = 'https://www.full360.com'
  s.license     = 'MIT'
  s.platform = 'java'
  
  s.add_runtime_dependency 'logger','~>1.2'
  s.add_development_dependency 'minitest','~>5.9'
  s.add_runtime_dependency 'git','~> 1.3'
  s.add_runtime_dependency "jdbc_helpers",'>= 0.0.6'
  s.add_runtime_dependency "zip",'>= 0.9'
  s.add_runtime_dependency "thor",'~> 0.19'
  s.add_runtime_dependency "dotenv", '~> 2.1'
  s.required_ruby_version = '>= 2.0' 
end
