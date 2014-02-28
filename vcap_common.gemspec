require File.expand_path('../lib/cf/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'vcap_common'
  s.version = Cf::VERSION.dup
  s.summary = 'vcap common'
  s.homepage = 'http://github.com/cloudfoundry/vcap-common'
  s.description = 'common vcap classes/methods'

  s.authors = ['Cloud Foundry Core Team']
  s.email = ['vcap-dev@googlegroups.com']

  s.add_dependency('eventmachine')
  s.add_dependency('thin')
  s.add_dependency('yajl-ruby')
  s.add_dependency('nats', '>= 0.5.0.beta.12', '< 0.6')
  s.add_dependency('posix-spawn', '~> 0.3.6')
  s.add_dependency('membrane', '~> 1.0')
  s.add_dependency('httpclient')
  s.add_dependency('em-http-request', '~> 1.0')
  s.add_dependency('multipart-post')
  s.add_dependency('mime-types')
  s.add_dependency('uuidtools')
  s.add_dependency('vmstat', '~> 2.0')
  s.add_dependency('squash_ruby')
  s.add_dependency('addressable', '~> 2.2')
  s.add_dependency('steno')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('sinatra')
  s.add_development_dependency('webmock')
  s.add_development_dependency('debugger')

  s.require_paths = ['lib']

  s.files = Dir['lib/**/*.rb'] + Dir['bin/*']
end
