# frozen_string_literal: true

require 'open-uri'
require 'pathname'

require_relative 'submission_excel2xml/version'

module SubmissionExcel2xml
  def self.xsd_path
    data_home = ENV.fetch('XDG_DATA_HOME') { File.expand_path('~/.local/share') }

    Pathname.new(data_home).join('submission-excel2xml/xsd')
  end
end
