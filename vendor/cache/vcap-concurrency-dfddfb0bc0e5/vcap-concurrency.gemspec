# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "vcap-concurrency"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["VMware"]
  s.date = "2013-07-02"
  s.description = "Provides utility classes to support common patterns in concurrent programming."
  s.email = ["support@vmware.com"]
  s.files = [".gitignore", "Gemfile", "LICENSE", "README.md", "Rakefile", "lib/vcap/concurrency.rb", "lib/vcap/concurrency/atomic_var.rb", "lib/vcap/concurrency/errors.rb", "lib/vcap/concurrency/promise.rb", "lib/vcap/concurrency/proxy.rb", "lib/vcap/concurrency/thread_pool.rb", "lib/vcap/concurrency/version.rb", "spec/atomic_var_spec.rb", "spec/promise_spec.rb", "spec/proxy_spec.rb", "spec/spec_helper.rb", "spec/thread_pool_spec.rb", "vcap-concurrency.gemspec"]
  s.homepage = "http://www.cloudfoundry.org"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Concurrency related utility classes"
  s.test_files = ["spec/atomic_var_spec.rb", "spec/promise_spec.rb", "spec/proxy_spec.rb", "spec/spec_helper.rb", "spec/thread_pool_spec.rb"]

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
