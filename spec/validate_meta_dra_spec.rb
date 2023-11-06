require 'spec_helper'

require 'json'
require 'open3'

RSpec.describe 'validate_meta_dra' do
  around do |example|
    Dir.chdir rspec_root.join('fixtures/files'), &example
  end

  example do
    out, status = Open3.capture2e('bundle exec validate_meta_dra -a example -i 0001 --machine-readable')

    expect(status).to be_success
    expect(JSON.parse(out)).to eq([])
  end
end
