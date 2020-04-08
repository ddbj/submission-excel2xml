#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'date'
require 'nokogiri'
require 'optparse'

#
# Bioinformation and DDBJ Center
# Validate Submission, Experiment and Run metadata XMLs for DDBJ Sequence Read Archive (DRA) submission.
# This program performs minimum check before uploading XMLs.
# Most validation are done during XML registration process in D-way.
# 2020-04-08 version 1.0 
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
puts "\n== XML validation against SRA xsd =="
if FileTest.exist?("#{submission_id}_Submission.xml")
	result = system("xmllint --schema SRA.submission.xsd --noout #{submission_id}_Submission.xml")
end

if FileTest.exist?("#{submission_id}_Experiment.xml")
	result = system("xmllint --schema SRA.experiment.xsd --noout #{submission_id}_Experiment.xml")
end

if FileTest.exist?("#{submission_id}_Run.xml")
	result = system("xmllint --schema SRA.run.xsd --noout #{submission_id}_Run.xml")
end

## object relation check
submission_a = []
submission_h = {}

experiment_alias_a = []
experiment_paired_alias_a = []
run_alias_a = []
run_files_a = []
run_experiment_a = []

## XML contents check
puts "\n== XML content check =="

# Submission
if FileTest.exist?("#{submission_id}_Submission.xml")

	doc_submission = Nokogiri::XML(open("#{submission_id}_Submission.xml"))

	doc_submission.css('SUBMISSION').each do |submission|
		
		hold = submission.at_css('HOLD').attribute("HoldUntilDate").value
		
		# check: hold date >= today
		if Date.parse(hold) < Date.today
			puts "Error: Submission: Past hold date"
		end	

	end # doc_submission.css('SUBMISSION')

end # if FileTest.exist?("#{submission_id}_Submission.xml")

# Experiment
if FileTest.exist?("#{submission_id}_Experiment.xml")

	doc_experiment = Nokogiri::XML(open("#{submission_id}_Experiment.xml"))

	doc_experiment.css('EXPERIMENT').each do |experiment|
	
		exp_aliase = experiment.attribute("alias").value
		experiment_alias_a.push(exp_aliase)

		if experiment.at_css('PAIRED')
			experiment_paired_alias_a.push(exp_aliase)
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
if FileTest.exist?("#{submission_id}_Run.xml")

	doc_run = Nokogiri::XML(open("#{submission_id}_Run.xml"))

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
