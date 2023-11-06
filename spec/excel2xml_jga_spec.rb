require 'spec_helper'

RSpec.describe 'excel2xml_jga' do
  around do |example|
    within_tmpdir &example
  end

  example do
    system "bundle exec excel2xml_jga -j JSUB999999 #{file_fixture('JSUB999999_jga_metadata.xlsx')}", exception: true, out: '/dev/null'

    expect(Dir.glob('**/*')).to match_array(%w(
      JSUB999999_Analysis.xml
      JSUB999999_Data.xml
      JSUB999999_Dataset.xml
      JSUB999999_Experiment.xml
      JSUB999999_Sample.xml
      JSUB999999_Study.xml
      JSUB999999_Submission.xml
    ))
  end
end
