require_relative 'lib/submission/excel2xml/version'

Gem::Specification.new do |spec|
  spec.name = 'submission-excel2xml'
  spec.version = Submission::Excel2xml::VERSION
  spec.authors = ['Bioinformation and DDBJ Center']
  # spec.email = ['ursm@ursm.jp']

  spec.summary = 'Tools for XML submission'
  # spec.description = 'TODO: Write a longer description or delete this line.'
  spec.homepage = 'https://github.com/ddbj/submission-excel2xml'
  spec.license = 'Apache-2.0'
  # spec.required_ruby_version = '>= 3.2.0'

  # spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = "TODO: Put your gem's public repo URL here."
  # spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'builder',  '~> 3'
  spec.add_dependency 'date',     '~> 3'
  spec.add_dependency 'nokogiri', '~> 1'
  spec.add_dependency 'open3',    '~> 0'
  spec.add_dependency 'rexml',    '~> 3'
  spec.add_dependency 'roo',      '~> 2'
  spec.add_dependency 'rubyzip',  '~> 2'
  spec.add_dependency 'xdg',      '~> 7'
end
