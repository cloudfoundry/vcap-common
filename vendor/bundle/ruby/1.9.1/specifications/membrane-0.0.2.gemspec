# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "membrane"
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["mpage"]
  s.date = "2012-07-09"
  s.description = "      Membrane provides an easy to use DSL for specifying validation\n      logic declaratively.\n"
  s.email = ["support@cloudfoundry.org"]
  s.homepage = "http://www.cloudfoundry.org"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "A DSL for validating data."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<ci_reporter>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<ci_reporter>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<ci_reporter>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
