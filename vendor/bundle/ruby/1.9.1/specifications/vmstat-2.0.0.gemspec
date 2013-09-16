# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "vmstat"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Vincent Landgraf"]
  s.date = "2012-10-27"
  s.description = "\n    A focused and fast library to gather memory, \n    cpu, network, load avg and disk information\n  "
  s.email = ["vilandgr@googlemail.com"]
  s.extensions = ["ext/vmstat/extconf.rb"]
  s.files = ["ext/vmstat/extconf.rb"]
  s.homepage = "http://threez.github.com/ruby-vmstat/"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "A focused and fast library to gather system information"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<rake-compiler>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, [">= 0"])
      s.add_development_dependency(%q<timecop>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rake-compiler>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, [">= 0"])
      s.add_dependency(%q<timecop>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rake-compiler>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, [">= 0"])
    s.add_dependency(%q<timecop>, [">= 0"])
  end
end
