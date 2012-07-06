spec = Gem::Specification.new do |s|
  s.name = 'vcap_common'
  s.version = '1.0.15'
  s.date = '2012-07-07'
  s.summary = 'vcap common'
  s.homepage = "http://github.com/vmware-ac/core"
  s.description = 'common vcap classes/methods'

  s.authors = ["Derek Collison"]
  s.email = ["derek.collison@gmail.com"]

  s.add_dependency('eventmachine')
  s.add_dependency('thin', '~> 1.3.1')
  s.add_dependency('yajl-ruby', '~> 0.8.3')
  s.add_dependency('nats', '~> 0.4.22.beta.8')
  s.add_dependency('posix-spawn', '~> 0.3.6')
  s.add_dependency('em-http-request', '~> 1.0.0.beta3')
  s.add_dependency('multipart-post')
  s.add_dependency('mime-types')
  s.add_development_dependency('rake', '~> 0.9.2')

  s.require_paths = ['lib']

  s.files = Dir["lib/**/*.rb"]
end
