# frozen_string_literal: true

require 'open-uri'
require 'xdg'

require_relative 'excel2xml/version'

module Excel2xml
  module_function

  def download_xsd_if_necessary
    return if xsd_path.exist?

    xsd_path.mkpath

    base_uri = 'https://raw.githubusercontent.com/ddbj/pub/master/docs'

    %w(analysis annotation common experiment package run sample study submission).each do |name|
      xsd_path.join("SRA.#{name}.xsd").write URI.open("#{base_uri}/dra/xsd/1-5/SRA.#{name}.xsd")
    end

    %w(analysis common dac data dataset experiment policy sample study submission).each do |name|
      xsd_path.join("JGA.#{name}.xsd").write URI.open("#{base_uri}/jga/xsd/1-2/JGA.#{name}.xsd")
    end
  end

  def xsd_path
    XDG.new.data_home.join('submission-excel2xml/xsd')
  end
end
