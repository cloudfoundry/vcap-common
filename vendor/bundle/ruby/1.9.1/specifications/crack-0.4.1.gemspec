# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "crack"
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker"]
  s.date = "2013-07-16"
  s.description = "Really simple JSON and XML parsing, ripped from Merb and Rails."
  s.email = ["nunemaker@gmail.com"]
  s.homepage = "http://github.com/jnunemaker/crack"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "Really simple JSON and XML parsing, ripped from Merb and Rails."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<safe_yaml>, ["~> 0.9.0"])
    else
      s.add_dependency(%q<safe_yaml>, ["~> 0.9.0"])
    end
  else
    s.add_dependency(%q<safe_yaml>, ["~> 0.9.0"])
  end
end
