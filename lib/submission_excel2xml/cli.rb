require 'thor'

require 'submission_excel2xml'

module SubmissionExcel2xml
  class CLI < Thor
    include Thor::Actions

    def self.exit_on_failure? = true

    desc 'download_xsd', 'Download xsd files'
    def download_xsd
      base = 'https://raw.githubusercontent.com/ddbj/pub/master/docs'

      %w(analysis annotation common experiment package run sample study submission).each do |part|
        url = "#{base}/dra/xsd/1-6/SRA.#{part}.xsd"

        get url, SubmissionExcel2xml.xsd_path.join(File.basename(url))
      end

      %w(analysis common dac data dataset experiment policy sample study submission).each do |part|
        url = "#{base}/jga/xsd/1-3/JGA.#{part}.xsd"

        get url, SubmissionExcel2xml.xsd_path.join(File.basename(url))
      end
    end
  end
end
