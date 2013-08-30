# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rack-protection"
  s.version = "1.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Konstantin Haase", "Alex Rodionov", "Chris Heald", "Chris Mytton", "Corey Ward", "David Kellum", "Egor Homakov", "Florian Gilcher", "Fojas", "Mael Clerambault", "Martin Mauch", "SAKAI, Kazuaki", "Stanislav Savulchik", "Steve Agalloco", "Akzhan Abdulin", "TOBY", "Bj\u{f8}rge N\u{e6}ss"]
  s.date = "2013-03-13"
  s.description = "You should use protection!"
  s.email = ["konstantin.mailinglists@googlemail.com", "p0deje@gmail.com", "self@hecticjeff.net", "coreyward@me.com", "dek-oss@gravitext.com", "homakov@gmail.com", "florian.gilcher@asquera.de", "developer@fojasaur.us", "mael@clerambault.fr", "martin.mauch@gmail.com", "kaz.july.7@gmail.com", "s.savulchik@gmail.com", "steve.agalloco@gmail.com", "akzhan.abdulin@gmail.com", "toby.net.info.mail+git@gmail.com", "bjoerge@bengler.no", "cheald@gmail.com"]
  s.homepage = "http://github.com/rkh/rack-protection"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.7"
  s.summary = "You should use protection!"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.0"])
  end
end
