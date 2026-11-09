# frozen_string_literal: true

require 'open3'
require 'json'
require 'rbconfig'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'excel2record_dra' do
  exe     = File.expand_path('../exe/excel2record_dra', __dir__)
  example = File.expand_path('../example/example-0001_dra_metadata.xlsx', __dir__)

  around do |spec|
    Dir.mktmpdir {|dir| Dir.chdir(dir) { spec.run } }
  end

  it 'writes a record of the Excel file, without what only ties the XML files together' do
    output, status = Open3.capture2e(RbConfig.ruby, '-I', File.expand_path('../lib', __dir__), exe, '-a', 'example', '-i', '0001', '-p', 'PRJDB7252', example)

    expect(status).to be_success, output

    record = JSON.parse(File.read('example-0001_dra_record.json'))

    expect(record['schema_version']).to eq('v3')
    expect(record['experiments']).not_to be_empty
    expect(record['runs']).not_to be_empty
    expect(record['submission']['sra']['actions'].map { _1['type'] }).not_to include('ADD')
    expect(record['relations'].map { _1['type'] }).to include('part_of')
    expect(record['submission']).not_to have_key('accession')
  end

  it 'fails where excel2xml_dra does' do
    output, status = Open3.capture2e(RbConfig.ruby, '-I', File.expand_path('../lib', __dir__), exe, '-a', 'example', '-i', '0001', 'none.xlsx')

    expect(status).not_to be_success, output
    expect(Dir['*_record.json']).to be_empty
  end

  def run(*args) = Open3.capture2e(RbConfig.ruby, '-I', File.expand_path('../lib', __dir__), File.expand_path('../exe/excel2record_dra', __dir__), *args)

  it 'takes a workbook by a path relative to where it is run, and keeps the hold date' do
    FileUtils.cp example, 'book.xlsx'

    output, status = run('-a', 'example', '-i', '0001', '-p', 'PRJDB7252', 'book.xlsx')

    expect(status).to be_success, output
    expect(JSON.parse(File.read('example-0001_dra_record.json')).dig('submission', 'hold_date')).to be_a(String)
  end

  it 'leaves an option value as it is, though a file has its name' do
    FileUtils.cp example, 'book.xlsx'

    run('-a', 'example', '-i', '0001', '-p', 'PRJDB7252', '-c', 'book.xlsx', 'book.xlsx')

    expect(JSON.parse(File.read('example-0001_dra_record.json')).dig('submission', 'center_name')).to eq('book.xlsx')
  end

  it 'refuses options a record could not be made by' do
    [
      ['-i', '0001', '-p', 'PRJDB7252', example],
      ['-a', 'example', '-i', '12', '-p', 'PRJDB7252', example],
      ['-a', 'example', '-i', '0001', '-p', 'PSUB000003', example],
      ['-a', 'example', '-i', '0001', example]
    ].each do |args|
      output, status = run(*args)

      expect(status).not_to be_success, output
    end

    expect(Dir['*_record.json']).to be_empty
  end
end
