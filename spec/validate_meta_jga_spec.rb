require 'spec_helper'

require 'json'
require 'open3'

RSpec.describe 'validate_meta_jga' do
  around do |example|
    Dir.chdir rspec_root.join('fixtures/files'), &example
  end

  example do
    out, status = Open3.capture2e('bundle exec validate_meta_jga -j JSUB999999')

    expect(status).to be_success

    expect(out).to eq(<<~OUT)
      JGA/AGD Submission ID: JSUB999999
      Error: Dataset to Policy ref
    OUT
  end
end
