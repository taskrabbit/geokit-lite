# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'geokit-lite'

Gem::Specification.new do |gem|
  gem.name          = "geokit-lite"
  gem.version       = GeokitLite::VERSION
  gem.authors       = ["Todd Eichel"]
  gem.email         = ["todd@toddeichel.com"]
  gem.description   = %q{A couple methods extracted from Geokit and Geokit Rails}
  gem.summary       = %q{A couple methods extracted from Geokit and Geokit Rails}
  gem.homepage      = "http://github.com/taskrabbit/geokit-lite"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
