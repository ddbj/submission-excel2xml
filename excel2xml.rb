#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'roo'
require 'builder'
require 'optparse'
require 'date'

#
# Bioinformation and DDBJ Center
# Generate Submission, Experiment and Run metadata XMLs for DDBJ Sequence Read Archive (DRA) submission.
# 2020-03-28 version 1.0 
# 2020-04-24 version 1.1 allow PSUB and SSUB IDs
# 2021-12-23 version 1.3 add bgiseq support
# 2022-12-13 version 1.4 spot type changes
#

# Options
account = ""
submission_no = ""
bioproject_accession = ""
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

	opt.on('-p [BioProject ID]', 'BioProject ID'){|v|
		raise "usage: -p BioProject ID (e.g., PRJDB100 or PSUB000003)" if v.nil? || !(/^PRJDB\d{1,}$/ =~ v || /^PSUB\d{1,}$/ =~ v)
		bioproject_accession = v
		puts "BioProject ID: #{v}"
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

# Function
# clean up float number
def clean_number(num)

	if num.is_a?(Float) && /\.0$/ =~ num.to_s
		return num.to_i
	else
		return num
	end

end

## Settings
# XML instruction
instruction = '<?xml version="1.0" encoding="UTF-8"?>'

### Read the DRA metadata excel

# open xlsx file
begin
	s = Roo::Excelx.new(ARGV[0])
rescue
	raise "No such file to open."
end

# metadata sheets
meta_object = ['Submission', 'Experiment', 'Run', 'Run-file']

# array for metadata objects
submission_a = Array.new
experiment_a = Array.new
run_a = Array.new
run_file_a = Array.new

# open a sheet and put data into an array with line number
for meta in meta_object

	s.default_sheet = meta

	i = 1 # line number
	for line in s
		
		case meta

		when "Submission" then
			submission_a.push([i, line])
		when "Experiment" then
			experiment_a.push([i, line])
		when "Run" then
			run_a.push([i, line])
		when "Run-file" then
			run_file_a.push([i, line])
		end

		i += 1

	end

end

## metadata content into hash

# Submission
i = 0 # array index number

center_name = ""
lab_name = ""
hold = ""
submitter_a = []

for num, line in submission_a

	if num == 2
		center_name = line[0].to_s
		lab_name = line[1].to_s
		hold = line[2].to_s
	end

	if num > 4 && line[0] && line[1]

		if line[0]
			submitter_a.push([line[0], line[1]])
		end

	end

end

# Experiment
experiments_a = Array.new
i = 0 # array index number
for num, line in experiment_a

	if /^Experiment-(\d{1,})/ =~ line[0].to_s

		alias_number = $1.rjust(4, "0")
		experiment_alias = "#{submission_id}_Experiment_#{alias_number}"

		if line[0]
			experiments_a.push(line[1,12].unshift(experiment_alias))
		end

	elsif line[0] && line[0].to_s != "" && /^Experiment-(\d{1,})/ !~ line[0].to_s && i > 0
		puts "Invalid Experiment alias format: #{line[0].to_s}. "
	end

	i += 1

end

# Run
runs_a = Array.new
i = 0 # array index number

for num, line in run_a

	if /^Run-(\d{1,})/ =~ line[0].to_s

		alias_number = $1.rjust(4, "0")
		run_alias = "#{submission_id}_Run_#{alias_number}"

		if line[0] && /^Experiment-(\d{1,})/ =~ line[2].to_s
			alias_number = $1.rjust(4, "0")
			to_experiment_alias = "#{submission_id}_Experiment_#{alias_number}"
			runs_a.push([run_alias, line[1], to_experiment_alias])
		end

	elsif line[0] && line[0].to_s != "" && /^Run-(\d{1,})/ !~ line[0].to_s && i > 0
		puts "Invalid Run alias format: #{line[0].to_s}. "
	end

	i += 1

end

# Run-file
run_files_a = Array.new
run_files_only_a = Array.new
i = 0 # array index number

for num, line in run_file_a

	if /^Run-(\d{1,})/ =~ line[1].to_s

		alias_number = $1.rjust(4, "0")
		run_alias = "#{submission_id}_Run_#{alias_number}"

		if line[0]
			run_files_a.push([line[0], run_alias, line[2], line[3]])
			run_files_only_a.push(line[0])
		end

	elsif line[1] && line[1].to_s != "" && /^Run-(\d{1,})/ !~ line[1].to_s && i > 0
		puts "Invalid Run alias format in Run-file: #{line[1].to_s}. "
	end

	i += 1

end

## filename duplication
duplicated_run_files_a = Array.new
duplicated_run_files_a = run_files_only_a.select{|e| run_files_only_a.count(e) > 1 }.sort.uniq

if duplicated_run_files_a.size > 0
	raise "Run file duplication: #{duplicated_run_files_a.join(",")}"
end

## Create XML
prefix = submission_id + "_"

# Submission
xml_submission = Builder::XmlMarkup.new(:indent=>4)

submission_f = open(prefix + "Submission.xml", "w")
submission_f.puts instruction

# Experiment
xml_experiment = Builder::XmlMarkup.new(:indent=>4)

experiment_f = open(prefix + "Experiment.xml", "w")
experiment_f.puts instruction

# Run
xml_run = Builder::XmlMarkup.new(:indent=>4)

run_f = open(prefix + "Run.xml", "w")
run_f.puts instruction

# Output Submission XML
if not submission_a.empty?
	
	submission_f.puts xml_submission.SUBMISSION("accession" => "", "center_name" => center_name, "lab_name" => lab_name, "alias" => "#{submission_id}_Submission", "submission_date" => Time.now.to_datetime.rfc3339){|submission|

			submission.CONTACTS{|contacts|

				for name, mail in submitter_a
					contacts.CONTACT("name" => name, "inform_on_error" => mail, "inform_on_status" => mail)
				end

			} # CONTACTS

			submission.ACTIONS{|actions|
			
				actions.ACTION{|action|
					action.ADD("source" => "#{submission_id}_Experiment.xml", "schema" => "experiment")
				}

				actions.ACTION{|action|
					action.ADD("source" => "#{submission_id}_Run.xml", "schema" => "run")
				}

				# check: hold date >= today
				if hold && Date.parse(hold) < Date.today
					raise "Error: Submission past hold date #{hold}"
				end	

				actions.ACTION{|action|
					action.HOLD("HoldUntilDate" => "#{hold}+09:00")
				}
			
			} # ACTIONS

	} # SUBMISSION

end

# output Experiment XML
exp_title_h = {}
experiment_f.puts xml_experiment.EXPERIMENT_SET{|experiment_set|

	for exp in experiments_a

		# auto-generate title if the experiment title is empty
		exp_title = ""
		biosample_accession = ""
		instrument_model = ""
		paired_seq = ""

		if exp[2] =~ /^SAMD\d{8}$/
			biosample_accession = exp[2]
		end

		if exp[8] && exp[8] != ""
			instrument_model = exp[8]
		end

		if exp[9] =~ /paired/
			paired_seq = "paired end sequencing"
		else
			paired_seq = "sequencing"
		end

		if exp[1].nil? || exp[1] == ""
			exp_title = "#{instrument_model} #{paired_seq} of #{biosample_accession}"
		else
			exp_title = exp[1]
		end

		exp_title_h.store(exp[0], exp_title)

		experiment_set.EXPERIMENT("accession" => "", "center_name" => center_name, "alias" => exp[0]){|experiment|

			experiment.TITLE(exp_title)
			
			if bioproject_accession =~ /^PRJDB\d{1,}$/
				experiment.STUDY_REF("accession" => bioproject_accession){|study_ref|
					study_ref.IDENTIFIERS{|identifiers|
						identifiers.PRIMARY_ID(bioproject_accession, "label" => "BioProject ID")
					}
				}
			elsif bioproject_accession =~ /^PSUB\d{1,}$/
				experiment.STUDY_REF{|study_ref|
					study_ref.IDENTIFIERS{|identifiers|
						identifiers.PRIMARY_ID(bioproject_accession, "label" => "BioProject Submission ID")
					}
				}
			end

			experiment.DESIGN{|design|
				
				design.DESIGN_DESCRIPTION()

				if exp[2] =~ /^SAMD\d{8}$/
					design.SAMPLE_DESCRIPTOR("accession" => exp[2]){|sample_ref|
						sample_ref.IDENTIFIERS{|identifiers|
							identifiers.PRIMARY_ID(exp[2], "label" => "BioSample ID")
						}
					}

					biosample_accession = exp[2]

				elsif exp[2] =~ /^(SSUB\d{6}) *: *(.*)$/
					sample_name = "#{$1} : #{$2}"
					design.SAMPLE_DESCRIPTOR{|sample_ref|
						sample_ref.IDENTIFIERS{|identifiers|
							identifiers.PRIMARY_ID(sample_name, "label" => "BioSample Submission ID")
						}
					}
				end

				design.LIBRARY_DESCRIPTOR{|lib_des|
					
					lib_des.LIBRARY_NAME(exp[3])					
					lib_des.LIBRARY_STRATEGY(exp[6])
					lib_des.LIBRARY_SOURCE(exp[4])
					lib_des.LIBRARY_SELECTION(exp[5])

					lib_des.LIBRARY_LAYOUT{|layout|
						if exp[9] =~ /paired/ && exp[10]
							layout.PAIRED("NOMINAL_LENGTH" => exp[10].to_i)
							paired_seq = "paired end sequencing"
						elsif exp[9] =~ /paired/
							layout.PAIRED
							paired_seq = "paired end sequencing"
						else
							layout.SINGLE
							paired_seq = "sequencing"
						end
					} # layout
					
					lib_des.LIBRARY_CONSTRUCTION_PROTOCOL(exp[7])

				} # lib_des

				# 454 paired
				if exp[9] =~ /paired/ && exp[8] =~ /454/

					design.SPOT_DESCRIPTOR{|spot_des|
						
						spot_des.SPOT_DECODE_SPEC{|decode|
							
							decode.READ_SPEC{|spec|
								spec.READ_INDEX("0")
								spec.READ_CLASS("Technical Read")
								spec.READ_TYPE("Adapter")
								spec.BASE_COORD("1")
							} # spec

							decode.READ_SPEC{|spec|
								spec.READ_INDEX("1")
								spec.READ_CLASS("Application Read")
								spec.READ_TYPE("Forward")
								spec.BASE_COORD("5")
							} # spec

							decode.READ_SPEC{|spec|
								spec.READ_INDEX("2")
								spec.READ_CLASS("Technical Read")
								spec.READ_TYPE("Linker")
								spec.EXPECTED_BASECALL_TABLE{|expected_basecall_table|
									expected_basecall_table.BASECALL("TCGTATAACTTCGTATAATGTATGCTATACGAAGTTATTACG", "min_match" => 38, "max_mismatch" => 5, "match_edge" => "full")
									expected_basecall_table.BASECALL("CGTAATAACTTCGTATAGCATACATTATACGAAGTTATACGA", "min_match" => 38, "max_mismatch" => 5, "match_edge" => "full")
								}
							} # spec

							decode.READ_SPEC{|spec|
								spec.READ_INDEX("3")
								spec.READ_CLASS("Application Read")
								spec.READ_TYPE("Forward")
								spec.RELATIVE_ORDER("follows_read_index" => 2)
							} # spec

						} # decode

					} # spot_des

				end # if 454 paired

				} # design

			experiment.PLATFORM{|platform|

				case exp[8]

				when /454/i
					platform.LS454{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				when /illumina|nextseq|hiseq/i
					platform.ILLUMINA{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				when /solid/i
					platform.ABI_SOLID{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				when /AB 5500/
					platform.ABI_SOLID{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				when /Ion/
					platform.ION_TORRENT{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				when /pacbio/i
					platform.PACBIO_SMRT{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}
				when /Sequel/
					platform.PACBIO_SMRT{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}
				when /ION/
					platform.OXFORD_NANOPORE{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				when /AB 3/
						platform.CAPILLARY{|platform_e|
							platform_e.INSTRUMENT_MODEL(exp[8])
						}
				when /Helicos HeliScope/
					platform.HELICOS{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				when /Complete/					
					platform.COMPLETE_GENOMICS{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				when /bgiseq|dnbseq|mgiseq/i				
					platform.BGISEQ{|platform_e|
						platform_e.INSTRUMENT_MODEL(exp[8])
					}

				end

				instrument_model = exp[8]

			} #platform

			# processing
			experiment.PROCESSING{|processing|
				processing.PIPELINE{|pipeline|
					pipeline.PIPE_SECTION{|pipe_section|
						pipe_section.STEP_INDEX("1")
	                    pipe_section.PREV_STEP_INDEX("NIL")
	                    pipe_section.PROGRAM
	                    pipe_section.VERSION
					}
				}
			}			

		} # exp

	end

}

# Run
if not runs_a.empty?
	
	run_f.puts xml_run.RUN_SET{|run_set|

		for run in runs_a

			run_set.RUN("accession" => "", "center_name" => center_name, "alias" => run[0]){|run_e|
				
				if exp_title_h[run[2]]
					run_e.TITLE(exp_title_h[run[2]])
				else
					run_e.TITLE("")
				end

				run_e.EXPERIMENT_REF("accession" => "", "refcenter" => center_name, "refname" => run[2])
				
				run_e.DATA_BLOCK{|block|
					
					block.FILES{|files|

						for run_file in run_files_a
						
							if run[0] == run_file[1]
														
								# fixed attributes: "checksum_method" => "MD5", "ascii_offset" => "!", "quality_encoding" => "ascii", "quality_scoring_system" => "phred"
								if run_file[3]
									files.FILE("checksum" => run_file[3].strip, "checksum_method" => "MD5", "ascii_offset" => "!", "quality_encoding" => "ascii", "quality_scoring_system" => "phred", "filetype" => run_file[2], "filename" => run_file[0])
									raise "Invalid MD5 checksum value: #{run_file[3].strip}" if run_file[3].strip !~ /^[a-f0-9]{32}$/i
								else
									files.FILE("checksum" => "", "checksum_method" => "MD5", "ascii_offset" => "!", "quality_encoding" => "ascii", "quality_scoring_system" => "phred", "filetype" => run_file[2], "filename" => run_file[0])
								end
								
							end
												
						end

					} # files

				} # block

			} # run_e

		end # for

	} # run_set

end
