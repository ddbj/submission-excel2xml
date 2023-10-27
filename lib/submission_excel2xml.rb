# frozen_string_literal: true

require 'open-uri'
require 'xdg'

require_relative 'submission_excel2xml/version'

module SubmissionExcel2xml
  def self.xsd_path = XDG.new.data_home.join('submission-excel2xml/xsd')
end
