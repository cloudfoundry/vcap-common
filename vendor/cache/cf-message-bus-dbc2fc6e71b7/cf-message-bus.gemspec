# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "cf-message-bus"
  s.version = "0.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["CloudFoundry Core Team"]
  s.date = "2013-08-26"
  s.description = "Abstraction layer around NATS messaging bus"
  s.email = ["cfpi-dev@googlegroups.com"]
  s.files = ["lib/cf_message_bus/message_bus.rb", "lib/cf_message_bus/message_bus_factory.rb", "lib/cf_message_bus/mock_message_bus.rb", "lib/cf_message_bus/version.rb", "lib/cf_message_bus.rb", "lib/eventmachine/schedule_sync.rb"]
  s.licenses = ["Apache"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Cloud Foundry message bus"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<eventmachine>, ["~> 1.0.0"])
      s.add_runtime_dependency(%q<nats>, ["= 0.4.26"])
      s.add_runtime_dependency(%q<vcap-concurrency>, [">= 0"])
      s.add_runtime_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_runtime_dependency(%q<vcap-concurrency>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<eventmachine>, ["~> 1.0.0"])
      s.add_dependency(%q<nats>, ["= 0.4.26"])
      s.add_dependency(%q<vcap-concurrency>, [">= 0"])
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<vcap-concurrency>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<eventmachine>, ["~> 1.0.0"])
    s.add_dependency(%q<nats>, ["= 0.4.26"])
    s.add_dependency(%q<vcap-concurrency>, [">= 0"])
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<vcap-concurrency>, [">= 0"])
  end
end
