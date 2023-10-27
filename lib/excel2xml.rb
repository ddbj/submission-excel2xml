# frozen_string_literal: true

require 'open-uri'
require 'xdg'

require_relative 'excel2xml/version'

module Excel2xml
  def self.xsd_path = XDG.new.data_home.join('submission-excel2xml/xsd')
end
