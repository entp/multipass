# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{multipass}
  s.version = "1.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["rick"]
  s.date = %q{2009-05-20}
  s.email = %q{technoweenie@gmail.com}
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["VERSION.yml", "lib/multipass.rb", "test/multipass_test.rb", "README", "LICENSE"]
  s.homepage = %q{http://github.com/entp/multipass}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Bare bones implementation of encoding and decoding MultiPass values for SSO.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ezcrypto>, [">= 0"])
    else
      s.add_dependency(%q<ezcrypto>, [">= 0"])
    end
  else
    s.add_dependency(%q<ezcrypto>, [">= 0"])
  end
end
