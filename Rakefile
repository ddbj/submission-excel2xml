require 'fileutils'

task :download_xsd do
  FileUtils.mkdir_p 'xsd'
  %w(analysis annotation common experiment package run sample study submission).each do |name|
    sh "wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.#{name}.xsd --output-document xsd/SRA.#{name}.xsd"
  end
  %w(analysis common dac data dataset experiment policy sample study submission).each do |name|
    sh "wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.#{name}.xsd --output-document xsd/JGA.#{name}.xsd"
  end
end
