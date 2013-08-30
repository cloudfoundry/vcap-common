# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "descendants_tracker"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Kubb", "Piotr Solnica", "Markus Schirp"]
  s.date = "2012-11-24"
  s.description = "Module that adds descendant tracking to a class"
  s.email = ["dan.kubb@gmail.com", "piotr.solnica@gmail.com", "mbj@seonic.net"]
  s.extra_rdoc_files = ["LICENSE", "README.md", "TODO"]
  s.files = ["LICENSE", "README.md", "TODO"]
  s.homepage = "https://github.com/dkubb/descendants_tracker"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "Module that adds descendant tracking to a class"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, ["~> 10.0.2"])
      s.add_development_dependency(%q<rspec>, ["~> 1.3.2"])
    else
      s.add_dependency(%q<rake>, ["~> 10.0.2"])
      s.add_dependency(%q<rspec>, ["~> 1.3.2"])
    end
  else
    s.add_dependency(%q<rake>, ["~> 10.0.2"])
    s.add_dependency(%q<rspec>, ["~> 1.3.2"])
  end
end
