require 'json'

module SubmissionExcel2xml
  # A DDBJ Record v3 (the form ddbj-repository takes DRA submissions in) from
  # the SRA XML documents excel2xml_dra writes.
  module DRARecord
    def self.call(documents)
      Converter.new(documents:).call.tap { without_file_handling(_1) }
    end

    # What only says how the XML files of a submission are read together.
    def self.without_file_handling(record)
      sra = record.dig('submission', 'sra') or return

      sra.delete('submission_date')

      return unless sra['actions']

      sra['actions'].reject! { _1['type'] == 'ADD' }
      sra.delete('actions') if sra['actions'].empty?
    end
  end
end

require_relative 'dra_record/converter'
