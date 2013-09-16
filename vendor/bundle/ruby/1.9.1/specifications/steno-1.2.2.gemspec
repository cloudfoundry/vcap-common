# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "steno"
  s.version = "1.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["mpage"]
  s.date = "2013-09-06"
  s.description = "A thread-safe logging library designed to support multiple log destinations."
  s.email = ["mpage@rbcon.com"]
  s.executables = ["steno-prettify"]
  s.files = ["bin/steno-prettify"]
  s.homepage = "http://www.cloudfoundry.org"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "A logging library."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<grape>, [">= 0"])
      s.add_runtime_dependency(%q<yajl-ruby>, ["~> 1.0"])
      s.add_runtime_dependency(%q<fluent-logger>, [">= 0"])
      s.add_development_dependency(%q<ci_reporter>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<grape>, [">= 0"])
      s.add_dependency(%q<yajl-ruby>, ["~> 1.0"])
      s.add_dependency(%q<fluent-logger>, [">= 0"])
      s.add_dependency(%q<ci_reporter>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<grape>, [">= 0"])
    s.add_dependency(%q<yajl-ruby>, ["~> 1.0"])
    s.add_dependency(%q<fluent-logger>, [">= 0"])
    s.add_dependency(%q<ci_reporter>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
