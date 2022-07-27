# frozen_string_literal: true

require_relative "lib/linkheaders/processor/version"

Gem::Specification.new do |spec|
  spec.name = "linkheaders-processor"
  spec.version = LinkHeaders::Processer::VERSION
  spec.authors = ["Mark Wilkinson"]
  spec.email = ["markw@illuminae.com"]

  spec.summary = "A parser/processor for Link Headers and Linksets in both JSON and Text formats."
  spec.description = "A parser/processor for Link Headers and Linksets in both JSON and Text formats."
  spec.homepage = "https://github.com/markwilkinson/linkheader-processor"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/markwilkinson/linkheader-processor"
  spec.metadata["changelog_uri"] = "https://github.com/markwilkinson/linkheader-processor/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.test_files = `git ls-files spec examples`.split("\n")
  # tests
  spec.add_development_dependency 'rspec'
  # benchmarks
  spec.add_dependency "rest-client", "~> 2.1"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "json-ld", "~> 3.2"
  spec.add_dependency "json-ld-preloaded", "~> 3.2"
  spec.add_dependency "securerandom", "~> 0.1.0"
  spec.add_dependency "metainspector", "~>5.11.2"

end
