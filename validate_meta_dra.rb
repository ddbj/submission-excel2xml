#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'date'
require 'rexml/document'
require 'nokogiri'
require 'optparse'
require 'open3'

#
# Bioinformation and DDBJ Center
# Validate Submission, Experiment and Run metadata XMLs for DDBJ Sequence Read Archive (DRA) submission.
# This program performs minimum check before uploading XMLs.
# Most validation are done during XML registration process in D-way.
# 2020-03-28 version 1.0
# 2020-04-24 version 1.1 check existence of nominal length for paired experiment
# 2022-12-14 version 1.2 DRA separated
# 2022-12-14 version 1.3 Nominal length was made optional for paired.
#

## Options
account = ""
submission_no = ""
OptionParser.new{|opt|

	opt.on('-a [VALUE]', 'D-way account ID'){|v|
		# accout id
		raise "usage: -a D-way account ID" if v.nil?
		account = v
		puts "D-way account ID: #{v}"
	}

	opt.on('-i [NUMBER]', 'submission number'){|v|
		raise "usage: -i submission number (e.g., 0001)" if v.nil? || !(/^\d{4}$/ =~ v)
		submission_no = v
		puts "Submission number: #{v}"
	}

	begin
		opt.parse!
	rescue
		puts "Invalid option. #{opt}"
	end

}

# submission id
submission_id = ""
if !(account == "" || submission_no == "")
	submission_id = account + "-" + submission_no
end

## Validate DRA XML against xsd
xsd_path = "/opt/submission-excel2xml/"
#xsd_path = "xsd/"

puts "\n== XML validation against SRA xsd =="
if FileTest.exist?("#{submission_id}_dra_Submission.xml")
	stdout, stderr, status = Open3.capture3("xmllint --schema #{xsd_path}SRA.submission.xsd --noout #{submission_id}_dra_Submission.xml")
	puts stderr
end

if FileTest.exist?("#{submission_id}_dra_Experiment.xml")
	stdout, stderr, status = Open3.capture3("xmllint --schema #{xsd_path}SRA.experiment.xsd --noout #{submission_id}_dra_Experiment.xml")
	puts stderr
end

if FileTest.exist?("#{submission_id}_dra_Run.xml")
	stdout, stderr, status = Open3.capture3("xmllint --schema #{xsd_path}SRA.run.xsd --noout #{submission_id}_dra_Run.xml")
	puts stderr
end

if FileTest.exist?("#{submission_id}_dra_Analysis.xml")
	stdout, stderr, status = Open3.capture3("xmllint --schema #{xsd_path}SRA.analysis.xsd --noout #{submission_id}_dra_Analysis.xml")
	puts stderr
end

## object relation check
submission_a = []
submission_h = {}

experiment_alias_a = []
experiment_paired_alias_a = []
experiment_paired_without_nominal_length_alias_a = []

run_alias_a = []
run_files_a = []
run_experiment_a = []

## XML contents check
puts "\n== XML content check =="

# Submission
if FileTest.exist?("#{submission_id}_dra_Submission.xml")

	doc_submission = Nokogiri::XML(open("#{submission_id}_dra_Submission.xml"))

	doc_submission.css('SUBMISSION').each do |submission|

		hold = submission.at_css('HOLD').attribute("HoldUntilDate").value

		# check: hold date >= today
		if Date.parse(hold) < Date.today
			puts "Error: Submission: Past hold date"
		end

	end # doc_submission.css('SUBMISSION')

end # if FileTest.exist?("#{submission_id}_Submission.xml")

# Experiment
if FileTest.exist?("#{submission_id}_dra_Experiment.xml")

	doc_experiment = Nokogiri::XML(open("#{submission_id}_dra_Experiment.xml"))

	doc_experiment.css('EXPERIMENT').each do |experiment|

		exp_aliase = experiment.attribute("alias").value
		experiment_alias_a.push(exp_aliase)

		if experiment.at_css('PAIRED')

			experiment_paired_alias_a.push(exp_aliase)

			# nominal length
			# unless experiment.at_css('PAIRED')['NOMINAL_LENGTH']
				# puts "Error: Experiment: #{exp_aliase} NOMINAL_LENGTH is required for paired library."
			# end

		end

	end # doc_experiment.css('EXPERIMENT')

end

# check: alias uniqueness
experiment_alias_dup_a = experiment_alias_a.select{|e| experiment_alias_a.count(e) > 1 }.uniq
unless experiment_alias_dup_a.empty?
	puts "Error: Experiment: Alias not unique: #{experiment_alias_dup_a.join(",")}"
end

# Run
run_file_number = 0
run_files_checksums_a = []
if FileTest.exist?("#{submission_id}_dra_Run.xml")

	doc_run = Nokogiri::XML(open("#{submission_id}_dra_Run.xml"))

	doc_run.css('RUN').each do |run|

		run_file_number = 0

		run_alias = run.attribute("alias").value
		run_alias_a.push(run_alias)

		# experiment_ref
		exp_ref = ""
		run.css("EXPERIMENT_REF").each do |experiment_ref|
			exp_ref = experiment_ref.attribute("refname").value
			run_experiment_a.push(exp_ref)
		end

		# data files
		run.css("FILE").each do |file|
			run_files_a.push(file.attribute("filename").value)
			run_file_number += 1
		end

		# md5
		run.css("FILE").each do |file|
			run_files_checksums_a.push([file.attribute("filename").value, file.attribute("checksum").value])
		end

		# paired file number check
		if experiment_paired_alias_a.include?(exp_ref)
			puts "Error: Run: #{run_alias} Paired library only has one file." if run_file_number == 1
		end

	end # doc_experiment.css('EXPERIMENT')

end

# check: alias uniqueness
run_alias_dup_a = run_alias_a.select{|e| run_alias_a.count(e) > 1 }.uniq
unless run_alias_dup_a.empty?
	puts "Error: Run: Alias not unique: #{run_alias_dup_a.join(",")}"
end

# check: filename uniqueness
run_files_dup_a = run_files_a.select{|e| run_files_a.count(e) > 1 }.uniq
unless run_files_dup_a.empty?
	puts "Error: Run: Filename not unique: #{run_files_dup_a.join(",")}"
end

# Run -> Experiment
puts "\n== Object reference check =="

run_to_experiment_a = (run_experiment_a - experiment_alias_a).reject{|c| c.empty?}
experiment_to_run_a = (experiment_alias_a - run_experiment_a).reject{|c| c.empty?}

if !run_to_experiment_a.empty? || !experiment_to_run_a.empty?

	puts "Error: Run to Experiment reference error"

	puts "#{run_experiment_a.join(", ")}: experiment not exist." if !run_to_experiment_a.empty?
	puts "#{experiment_to_run_a.join(", ")}: unreferenced." if !experiment_to_run_a.empty?

else
	puts "Run to Experiment reference OK"
end

# md5 checksum check
for filename, checksum in run_files_checksums_a

	if checksum !~ /^[a-f0-9]{32}$/i
		puts "#{filename}:#{checksum} Invalid md5 checksum value."
	end

end

# Analysis
analysis_file_number = 0
analysis_files_checksums_a = []
analysis_alias_a = []
analysis_study_ref_a = []
analysis_files_a = []
analysis_checksums_a = []
if FileTest.exist?("#{submission_id}_dra_Analysis.xml")

	doc_analysis = Nokogiri::XML(open("#{submission_id}_dra_Analysis.xml"))

	doc_analysis.css('ANALYSIS').each do |analysis|

		analysis_file_number = 0

		analysis_alias = analysis.attribute("alias").value
		analysis_alias_a.push(analysis_alias)

		# study_ref
		study_ref = ""
		analysis.css("STUDY_REF").each do |study_ref|
			study_ref = study_ref.attribute("refname").value
			analysis_study_ref_a.push(study_ref)
		end

		# reference for REFERENCE_ALIGNMENT
		if analysis.at_css("REFERENCE_ALIGNMENT")
			unless analysis.at_css("STANDARD") && analysis.at_css("STANDARD").attribute("short_name") && analysis.at_css("STANDARD").attribute("short_name").value != ""
				puts "Reference is required for analysis type REFERENCE_ALIGNMENT. #{analysis_alias}"
			end
		end

		# data files
		analysis.css("FILE").each do |file|
			analysis_files_a.push(file.attribute("filename").value)
			analysis_file_number += 1

			analysis_checksums_a.push(file.attribute("checksum").value)
		end

	end # doc_analysis.css('ANALYSIS')

	# check: alias uniqueness
	analysis_alias_dup_a = analysis_alias_a.select{|e| analysis_alias_a.count(e) > 1 }.sort.uniq
	unless analysis_alias_dup_a.empty?
		puts "Error: Analysis alias not unique: #{analysis_alias_dup_a.join(",")}"
	end

	# check: filename uniqueness
	analysis_files_dup_a = analysis_files_a.select{|e| analysis_files_a.count(e) > 1 }.sort.uniq
	unless analysis_files_dup_a.empty?
		puts "Error: Analysis data filename not unique: #{analysis_files_dup_a.join(",")}"
	end

	# check: checksum uniqueness
	analysis_checksums_a = analysis_checksums_a.select{|e| analysis_checksums_a.count(e) > 1 }.sort.uniq
	unless analysis_checksums_a.empty?
		puts "Error: Analysis checksum of data file not unique: #{analysis_checksums_a.join(",")}"
	end

	# Analysis -> BioProject
	puts "\n== Object reference check =="

	if analysis_study_ref_a.sort.uniq.size == 1
		puts "Analysis to BioProject reference OK"
	else
		puts "Error: Analysis refers to more than one BioProject"
	end

	# md5 checksum check
	for checksum in analysis_checksums_a
		if checksum !~ /^[a-f0-9]{32}$/i
			puts "#{checksum} Invalid md5 checksum value."
		end
	end

end

