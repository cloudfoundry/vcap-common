spec = Gem::Specification.new do |s|
  s.name = 'vcap_common'
  s.version = '2.0.10'
  s.date = '2012-10-25'
  s.summary = 'vcap common'
  s.homepage = "http://github.com/vmware-ac/core"
  s.description = 'common vcap classes/methods'

  s.authors = ["Derek Collison"]
  s.email = ["derek.collison@gmail.com"]

  s.add_dependency('eventmachine')
  s.add_dependency('thin')
  s.add_dependency('yajl-ruby')
  s.add_dependency('nats', '~> 0.4.24')
  s.add_dependency('posix-spawn', '~> 0.3.6')
  s.add_dependency('membrane', '~> 0.0.2')
  s.add_dependency('httpclient')
  s.add_dependency('em-http-request', '~> 1.0.0.beta3', '< 1.0.0.beta4')
  s.add_dependency('multipart-post')
  s.add_dependency('mime-types')
  s.add_development_dependency('rake', '~> 0.9.2')
  s.add_development_dependency('rspec')
  s.add_development_dependency('sinatra')

  s.require_paths = ['lib']

  s.files = Dir["lib/**/*.rb"]
end
