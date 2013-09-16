# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "grape"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Bleigh"]
  s.date = "2013-06-14"
  s.description = "A Ruby framework for rapid API development with great conventions."
  s.email = ["michael@intridea.com"]
  s.homepage = "https://github.com/intridea/grape"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "grape"
  s.rubygems_version = "2.0.7"
  s.summary = "A simple Ruby framework for building REST-like APIs."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 1.3.0"])
      s.add_runtime_dependency(%q<rack-mount>, [">= 0"])
      s.add_runtime_dependency(%q<rack-accept>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>, [">= 1.3.2"])
      s.add_runtime_dependency(%q<multi_xml>, [">= 0.5.2"])
      s.add_runtime_dependency(%q<hashie>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<virtus>, [">= 0"])
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_development_dependency(%q<grape-entity>, [">= 0.2.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<maruku>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.9"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 1.3.0"])
      s.add_dependency(%q<rack-mount>, [">= 0"])
      s.add_dependency(%q<rack-accept>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<multi_json>, [">= 1.3.2"])
      s.add_dependency(%q<multi_xml>, [">= 0.5.2"])
      s.add_dependency(%q<hashie>, [">= 1.2.0"])
      s.add_dependency(%q<virtus>, [">= 0"])
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<grape-entity>, [">= 0.2.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<maruku>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.9"])
      s.add_dependency(%q<bundler>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 1.3.0"])
    s.add_dependency(%q<rack-mount>, [">= 0"])
    s.add_dependency(%q<rack-accept>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<multi_json>, [">= 1.3.2"])
    s.add_dependency(%q<multi_xml>, [">= 0.5.2"])
    s.add_dependency(%q<hashie>, [">= 1.2.0"])
    s.add_dependency(%q<virtus>, [">= 0"])
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<grape-entity>, [">= 0.2.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<maruku>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.9"])
    s.add_dependency(%q<bundler>, [">= 0"])
  end
end
