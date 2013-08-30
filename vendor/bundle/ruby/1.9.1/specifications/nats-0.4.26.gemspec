# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "nats"
  s.version = "0.4.26"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Derek Collison"]
  s.date = "2012-07-30"
  s.description = "A lightweight cloud messaging system."
  s.email = ["derek.collison@gmail.com"]
  s.executables = ["nats-server", "nats-pub", "nats-sub", "nats-queue", "nats-top", "nats-request"]
  s.files = ["bin/nats-server", "bin/nats-pub", "bin/nats-sub", "bin/nats-queue", "bin/nats-top", "bin/nats-request"]
  s.homepage = "http://github.com/derekcollison/nats"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "A lightweight cloud messaging system."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_runtime_dependency(%q<json_pure>, [">= 1.7.3"])
      s.add_runtime_dependency(%q<daemons>, [">= 1.1.5"])
      s.add_runtime_dependency(%q<thin>, [">= 1.4.1"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_dependency(%q<json_pure>, [">= 1.7.3"])
      s.add_dependency(%q<daemons>, [">= 1.1.5"])
      s.add_dependency(%q<thin>, [">= 1.4.1"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
    s.add_dependency(%q<json_pure>, [">= 1.7.3"])
    s.add_dependency(%q<daemons>, [">= 1.1.5"])
    s.add_dependency(%q<thin>, [">= 1.4.1"])
  end
end
