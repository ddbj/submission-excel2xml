require 'fileutils'
require 'open-uri'

task :download_xsd do
  FileUtils.mkdir_p 'xsd'

  %w(analysis annotation common experiment package run sample study submission).each do |name|
    URI.open "https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.#{name}.xsd" do |f|
      IO.copy_stream f, "xsd/SRA.#{name}.xsd"
    end
  end

  %w(analysis common dac data dataset experiment policy sample study submission).each do |name|
    URI.open "https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.#{name}.xsd" do |f|
      IO.copy_stream f, "xsd/JGA.#{name}.xsd"
    end
  end
end
