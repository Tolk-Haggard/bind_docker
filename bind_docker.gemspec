Gem::Specification.new do |s|
  s.name        = 'bind_docker'
  s.version     = '0.1.0'
  s.date        = '2016-01-20'
  s.summary     = "Build Docker containers running Bind9"
  s.description = "Gem to create a docker container running bind9, used with rpsec for UATs"
  s.authors     = ["Brian Haggard", "Brian Felton", "Rebecca Skinner"]
  s.email       = 'brihagg@gmail.com'
  s.files       = ["lib/bind_docker.rb"]
  s.homepage    = 'http://rubygems.org/gems/bind_docker'
  s.license     = 'MIT'
  s.add_runtime_dependency 'json', '~> 1.4'
  s.add_runtime_dependency 'dnsruby', '~> 1.58'
end
