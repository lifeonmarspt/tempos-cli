# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tempos/version"

Gem::Specification.new do |spec|
  spec.name          = "tempos-cli"
  spec.version       = Tempos::Cli::VERSION
  spec.authors       = ["Hugo Peixoto"]
  spec.email         = ["hugo@lifeonmars.pt"]

  spec.summary       = %q{Keep track of time spent on each of your clients' projects}
  spec.homepage      = "https://github.com/lifeonmarspt/tempos-bot"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0"
  spec.add_dependency "chronic_duration", "~> 0"
  spec.add_development_dependency "bundler", "~> 1.15"
end
