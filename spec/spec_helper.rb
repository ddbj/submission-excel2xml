# frozen_string_literal: true

require 'submission-excel2xml'

require 'tmpdir'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Module.new {
    def rspec_root
      Pathname.new(__dir__)
    end

    def file_fixture(path)
      rspec_root.join('fixtures/files', path)
    end

    def within_tmpdir(&block)
      Dir.mktmpdir do |dir|
        Dir.chdir dir, &block
      end
    end
  }
end
