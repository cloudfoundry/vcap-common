# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "atomic"
  s.version = "1.1.13"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Charles Oliver Nutter", "MenTaLguY", "Sokolov Yura"]
  s.date = "2013-08-14"
  s.description = "An atomic reference implementation for JRuby, Rubinius, and MRI"
  s.email = ["headius@headius.com", "mental@rydia.net", "funny.falcon@gmail.com"]
  s.extensions = ["ext/extconf.rb"]
  s.files = ["ext/extconf.rb"]
  s.homepage = "http://github.com/headius/ruby-atomic"
  s.licenses = ["Apache-2.0"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "An atomic reference implementation for JRuby, Rubinius, and MRI"
end
