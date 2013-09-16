# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "thread_safe"
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Charles Oliver Nutter"]
  s.date = "2013-07-24"
  s.description = "Thread-safe collections and utilities for Ruby"
  s.email = ["headius@headius.com"]
  s.homepage = "https://github.com/headius/thread_safe"
  s.licenses = ["Apache-2.0"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "A collection of data structures and utilities to make thread-safe programming in Ruby easier"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<atomic>, [">= 0"])
    else
      s.add_dependency(%q<atomic>, [">= 0"])
    end
  else
    s.add_dependency(%q<atomic>, [">= 0"])
  end
end
