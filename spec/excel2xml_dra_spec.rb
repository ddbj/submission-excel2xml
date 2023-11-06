require 'spec_helper'

RSpec.describe 'excel2xml_dra' do
  around do |example|
    within_tmpdir &example
  end

  example 'w/o Analysis' do
    system "bundle exec excel2xml_dra -a example -i 0001 -p PRJDB7252 #{file_fixture('example-0001_dra_metadata.xlsx')}", exception: true, out: '/dev/null'

    expect(Dir.glob('**/*')).to match_array(%w(
      example-0001_dra_Submission.xml
      example-0001_dra_Experiment.xml
      example-0001_dra_Run.xml
    ))
  end

  example 'w/ Analysis' do
    system "bundle exec excel2xml_dra -a example -i 0002 -p PRJDB7252 #{file_fixture('example-0002_dra_metadata.xlsx')}", exception: true, out: '/dev/null'

    expect(Dir.glob('**/*')).to match_array(%w(
      example-0002_dra_Submission.xml
      example-0002_dra_Experiment.xml
      example-0002_dra_Run.xml
      example-0002_dra_Analysis.xml
    ))
  end
end
