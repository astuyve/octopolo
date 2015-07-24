# -*- encoding: utf-8 -*-
require File.expand_path('../lib/octopolo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Patrick Byrne", "Luke Ludwig"]
  gem.email         = ["patrick.byrne@sportngin.com", "luke.ludwig@sportngin.com"]
  gem.description   = %q{A set of Github workflow scripts.}
  gem.summary       = %q{A set of Github workflow scripts.}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "octopolo"
  gem.license       = "MIT"
  gem.require_paths = ["lib"]
  gem.version       = Octopolo::VERSION

  gem.add_dependency 'rake'
  gem.add_dependency 'gli', '~> 2.13'
  gem.add_dependency 'hashie', '~> 1.2'
  gem.add_dependency 'octokit', '~> 4.0.1'
  gem.add_dependency 'highline', '~> 1.6'
  gem.add_dependency 'pivotal-tracker', '~> 0.5'
  gem.add_dependency 'jiralicious'
  gem.add_dependency 'semantic', '~> 1.3.0'

  gem.add_development_dependency 'rspec', '~> 2.99.0'
  gem.add_development_dependency "guard"
  gem.add_development_dependency "guard-rspec"
  gem.add_development_dependency 'octopolo-plugin-example'
end
