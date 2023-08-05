# frozen_string_literal: true

require_relative "lib/pg_delta/version"

Gem::Specification.new do |spec|
  spec.name = "pg_delta"
  spec.version = PgDelta::Version::VERSION
  spec.authors = ["rhizomic"]

  spec.summary = "Summarizes the changes made by PostgreSQL migrations."
  spec.description = "pg_delta concisely summarizes the changes made by PostgreSQL migrations."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["source_code_uri"] = "https://github.com/rhizomic/pg_delta"
  spec.metadata["changelog_uri"] = "https://github.com/rhizomic/pg_delta/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", ">= 13.0.6"
  spec.add_development_dependency "minitest", ">= 5.19.0"
  spec.add_development_dependency "standard", ">= 1.30.1"

  spec.add_dependency "pg_query", ">= 4.2.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
