# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "delayed_job_active_record_threaded"
  spec.authors       = ["Abdo Achkar"]
  spec.email         = ["abdo.achkar@gmail.com"]
  spec.description   = %q{Allows going through delayed job queues using threads instead of processes}
  spec.summary       = %q{Process the delayed job queue using threads.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "minitest", "~> 4.7.3"
  spec.add_development_dependency "rails", ['>= 3.0', '< 4.1']
  spec.add_development_dependency "turn"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'sqlite3-ruby', '>= 1.3.1'
  spec.add_dependency   'activerecord', ['>= 3.0', '< 4.1']
  spec.add_dependency   'delayed_job',  ['>= 3.0', '< 4.1']
  spec.version = "0.0.1"
end
