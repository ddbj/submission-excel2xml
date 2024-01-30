require_relative 'lib/submission_excel2xml/version'

Gem::Specification.new do |spec|
  spec.name    = 'submission-excel2xml'
  spec.version = SubmissionExcel2xml::VERSION
  spec.authors = ['Bioinformation and DDBJ Center']

  spec.summary  = 'Tools for XML submission'
  spec.homepage = 'https://github.com/ddbj/submission-excel2xml'
  spec.license  = 'Apache-2.0'

  spec.files = Dir[
    'exe/*',
    'lib/**/*',
    'LICENSE.txt',
    'README.md'
  ]

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
  spec.add_dependency 'thor',     '~> 1'
end
