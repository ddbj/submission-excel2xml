#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'roo'
require 'builder'
require 'optparse'

#
# Bioinformation and DDBJ Center
# Japanese Genotype-phenotype Archive
#

# Update history
# 2022-12-23 change handling of submission date
# 2022-12-22 AGD
# 2022-12-14 publicly released

### Options
account = ""
submission_no = ""
submission_id = ""
study_accession = ""
OptionParser.new{|opt|

	opt.on('-j [JSUB ID]', 'JSUB/ASUB submission ID'){|v|
		raise "usage: -j JGA/AGD submission ID (JSUB000001 or ASUB000001)" if v.nil? || !(/^[JA]SUB\d{6}$/ =~ v)
		submission_id = v
		puts "JGA/AGD Submission ID: #{v}"
	}

	opt.on('-s [study accession]', 'JGA/AGD study accession'){|v|
		raise "usage: -j study accession (JGAS000001 or AGDS_000001)" if !(/^(JGAS|AGDS_)\d{6}$/ =~ v)
		study_accession = v
		puts "JGA/AGD Study Accession: #{v}"
	}

	begin
		opt.parse!
	rescue
		puts "Invalid option. #{opt}"
	end

}

### Function
def clean_number(num)

	if num.is_a?(Float) && /\.0$/ =~ num.to_s
		return num.to_i
	else
		return num
	end

end

### Settings
# instruction
instruction = '<?xml version="1.0" encoding="UTF-8"?>'

### Read the JGA submission excel file

# open xlsx file
begin
	s = Roo::Excelx.new(ARGV[0])
rescue
	raise "No such file to open."
end

# sheets
meta_object = ['Submission', 'Study', 'Sample', 'Experiment', 'Data', 'Analysis', 'Dataset', 'File']

# array for metadata objects
submission_a = Array.new
study_a = Array.new
sample_a = Array.new
experiment_a = Array.new
data_a = Array.new
analysis_a = Array.new
dataset_a = Array.new
file_a = Array.new

# open a sheet and put data into an array with line number
for meta in meta_object

	s.default_sheet = meta

	i = 1 # line number
	for line in s

		case meta

		when "Submission" then
			submission_a.push([i, line])
		when "Study" then
			study_a.push([i, line])
		when "Sample" then
			sample_a.push([i, line])
		when "Experiment" then
			experiment_a.push([i, line])
		when "Data" then
			data_a.push([i, line])
		when "Analysis" then
			analysis_a.push([i, line])
		when "Dataset" then
			dataset_a.push([i, line])
		when "File" then
			file_a.push([i, line])
		end

		i += 1
	end

end

## content into hash

# Submission
submission_h = Hash.new
i = 0 # array index number

# alias
submission_h.store("alias", submission_id + "_Submission_000001")
for num, line in submission_a

	if (line[0] == "NBDC Number (hum)") || (line[0] == "NBDC Submission Number")
		submission_h.store("nbdc_number", submission_a[i+1][1][0])
	end

	if line[0] == "Hold/Release"
		submission_h.store("hold", submission_a[i+1][1][0])
	end

	if line[0] == "Contacts"
		j = num
		contact_a = Array.new
		pi_a = Array.new
		while submission_a[j][1][0] && /\d/ =~ submission_a[j][1][0].to_s && submission_a[j][1][3] # if there is a number and mail address

			# PI
			if /Principal Investigator/ =~ submission_a[j][1][0].to_s
				# center name is fixed to Individual
				submission_h.store("center_name", "Individual")
				submission_h.store("organization", submission_a[j][1][5])
				pi_a.push(submission_a[j][1][1..5])
			end

			contact_a.push(submission_a[j][1][1..5])
			j += 1

		end

		submission_h.store("contacts", contact_a)
		# PI
		submission_h.store("pi", pi_a)

	end

	if line[0] == "Submission Date"
		if submission_a[i+1] && submission_a[i+1][1] && submission_a[i+1][1][0] && submission_a[i+1][1][0].strftime("%Y-%m-%dT00:00:00+09:00")
			submission_h.store("submission_date", submission_a[i+1][1][0].strftime("%Y-%m-%dT00:00:00+09:00"))
		else
			submission_h.store("submission_date", Date.today.strftime("%Y-%m-%dT00:00:00+09:00"))
			puts "Warning: The submission date is empty. Today #{Date.today.strftime("%Y-%m-%dT00:00:00+09:00")} is used."
		end
	end

	i += 1

end

# Study
study_h = Hash.new
i = 0 # array index number
for num, line in study_a

	if line[0] == "Title"
		study_h.store("Title", study_a[i+1][1][0])
	end

	if line[0] == "Study Types"
		j = num
		study_type_a = Array.new
		while study_a[j][1][0] && /\d/ =~ study_a[j][1][0].to_s # if number
			study_type_a.push(study_a[j][1][1..2])
			j += 1
		end

		study_h.store("study_type", study_type_a)

	end

	if line[0] == "Abstract"
		study_h.store("Abstract", study_a[i+1][1][0])
	end

	# Molecular Data Type
	if line[0] == "Molecular Data Type"
		j = num
		molecular_data_type_a = Array.new
		while study_a[j][1][0] && /\d/ =~ study_a[j][1][0].to_s # if number
			if !(study_a[j][1][1].nil? && study_a[j][1][2].nil?) # if both are not nil
				molecular_data_type_a.push(study_a[j][1][1..4])
			end
			j += 1
		end

		study_h.store("molecular_data_type", molecular_data_type_a)

	end

	# Diseases/Traits/Exposures related to the study
	if line[0] == "Diseases/Traits/Exposures related to the study"
		j = num
		phenotype_disease_terms_a = Array.new
		while study_a[j][1][0] && /\d/ =~ study_a[j][1][0].to_s # if number
			if !(study_a[j][1][1].nil? && study_a[j][1][2].nil?) # if both are not nil
				phenotype_disease_terms_a.push(study_a[j][1][1])
			end
			j += 1
		end

		study_h.store("phenotype_disease_terms", phenotype_disease_terms_a)

	end

	# Inclusion/Exclusion Criteria
	if line[0] == "Inclusion/Exclusion Criteria"
		study_h.store("inclusion_exclusion_criteria", study_a[i+1][1][0])
	end

	# Disease classification(s), ICD-10
	if line[0] == "Disease classification(s)"
		j = num
		disease_type_a = Array.new
		while study_a[j][1][0] && /\d/ =~ study_a[j][1][0].to_s # if number
			if !(study_a[j][1][1].nil? && study_a[j][1][2].nil?) # if both are not nil
				disease_type_a.push([study_a[j][1][1], study_a[j][1][2]])
			end
			j += 1
		end

		study_h.store("disease_classification", disease_type_a)

	end

	if line[0] == "Publications"
		j = num
		publication_a = Array.new
		while study_a[j][1][0] && /\d/ =~ study_a[j][1][0].to_s # if number
			if !(study_a[j][1][1].nil? && study_a[j][1][2].nil?) # if both are not nil
				publication_a.push(study_a[j][1][1..2])
			end
			j += 1
		end

		study_h.store("publication", publication_a)

	end

	if line[0] == "Grants"
		j = num
		grant_a = Array.new
		while study_a[j][1][0]# && /\d/ =~ study_a[j][1][0].to_s # if number
			if !(study_a[j][1][1..4].compact.empty?) # if there is a first item
				grant_a.push(study_a[j][1][1..4])
			end
			j += 1
		end

		study_h.store("grant", grant_a)

	end

	if line[0] == "Links"
		j = num
		link_a = Array.new
		while study_a[j] && study_a[j][1] && study_a[j][1][0] && /\d/ =~ study_a[j][1][0].to_s # if number and not at last line
			if study_a[j][1][1] # if there is a first item
				link_a.push(study_a[j][1][1])
			end
			j += 1
		end

		study_h.store("link", link_a)

	end

	if line[0] == "Attributes"
		j = num
		attribute_a = Array.new
		while study_a[j] && study_a[j][1] && study_a[j][1][0] && /\d/ =~ study_a[j][1][0].to_s # if number and not at last line
			if !(study_a[j][1][1].nil? && study_a[j][1][2].nil?) # if both are not nil
				attribute_a.push(study_a[j][1][1..2])
			end
			j += 1
		end

		study_h.store("attribute", attribute_a)

	end

	i += 1

end

# Sample
samples_a = Array.new
sample_aliases_a = Array.new
i = 0 # array index number

for num, line in sample_a

	if /^Sample-\d{1,6}/ =~ line[0]
		# alias
		sample_number = line[0].split("-")[1].to_i
		sample_alias = submission_id + "_Sample_" + sprintf("%06d", line[0].split("-")[1].to_i)
		sample_aliases_a.push(sample_alias)

		# Title があれば
		if line[4]
			samples_a.push([sample_alias, line[1], line[2], line[3], line[4], line[5], line[6], line[7], line[8], line[9], line[10], line[11]])
		end

	end

end

# Experiment
experiments_a = Array.new
experiment_aliases_a = Array.new
i = 0 # array index number
for num, line in experiment_a

	if /^Experiment-\d{1,6}/ =~ line[0]

		# alias
		experiment_number = line[0].split("-")[1].to_i
		experiment_alias = submission_id + "_Experiment_" + sprintf("%06d", line[0].split("-")[1].to_i)
		experiment_aliases_a.push(experiment_alias)

		# NGS
		if (line[1] && line[2] && line[3] && line[4] && line[5] && line[6]) && line[7] && line[8] && line[9] && line[10]

			if line[1] =~ /Sample-\d{1,}/
				sample_ref = submission_id + "_Sample_" + sprintf("%06d", line[1].split("-")[1].to_i)
			elsif line[1] =~ /(JGAN|AGDN_)\d{9}/
				sample_ref = line[1]
			end

			experiments_a.push([experiment_alias, sample_ref, line[2], line[3], line[4], line[5], line[6], line[7], line[8], line[9], line[10], clean_number(line[11]), clean_number(line[12]), line[13], clean_number(line[14]), line[15], clean_number(line[16]), line[17], line[18], line[19], line[20], line[21], line[22], line[23]])

		end

	end

end

# Data
datas_a = Array.new
data_aliases_a = Array.new
for num, line in data_a
	if /^Data-\d{1,6}/ =~ line[0]

		# alias
		data_number = line[0].split("-")[1].to_i
		data_alias = submission_id + "_Data_" + sprintf("%06d", line[0].split("-")[1].to_i)
		data_aliases_a.push(data_alias)

		# NGS
		if line[1] && line[2] && line[3]

			if line[1] =~ /Experiment-\d{1,}/
				experiment_ref = submission_id + "_Experiment_" + sprintf("%06d", line[1].split("-")[1].to_i)
			elsif line[1] =~ /(JGAX|AGDX_)\d{9}/
				experiment_ref = line[1]
			end

			datas_a.push([data_alias, experiment_ref, line[2], line[3], line[4], line[5], "data_ngs"])

		end

	end

end

# Analysis
analyses_a = Array.new
analyses_aliases_a = Array.new
for num, line in analysis_a
	if /^Analysis-\d{1,6}/ =~ line[0]

		# alias
		analysis_alias = submission_id + "_Analysis_" + sprintf("%06d", line[0].split("-")[1].to_i)
		analyses_aliases_a.push(analysis_alias)

		if line[4] && line[5] && line[6] && line[7] && line[8]

			# STUDY_REF
			if line[1] =~ /Study-\d{1,}/
				study_ref = submission_id + "_Study_" + sprintf("%06d", line[1].split("-")[1].to_i)
			elsif line[1] =~ /(JGAS|AGDS_)\d{6}/
				study_ref = line[1]
			else
				study_ref = nil
			end

			# SAMPLE_REF
			sample_ref_a = []
			if line[2]

 				line[2].split(",").each{|sample_ref|

 					sample_ref = sample_ref.strip

					if sample_ref =~ /Sample-\d{1,}/
						sample_ref = submission_id + "_Sample_" + sprintf("%06d", sample_ref.split("-")[1].to_i)
						sample_ref_a.push(sample_ref)
					elsif sample_ref =~ /(JGAN|AGDN_)\d{9}/
						sample_ref_a.push(sample_ref)
					else
						raise "Invalid sample ref from Analysis: #{sample_ref}"
					end
 				}

			end

			# DATA_REF
			data_ref_a = []
			if line[3]

 				line[3].split(",").each{|data_ref|

 					data_ref = data_ref.strip

					if data_ref =~ /Data-\d{1,}/
						data_ref = submission_id + "_Data_" + sprintf("%06d", data_ref.split("-")[1].to_i)
						data_ref_a.push(data_ref)
					elsif data_ref =~ /(JGAR|AGDR_)\d{9}/
						data_ref_a.push(data_ref)
					else
						raise "Invalid data ref from Analysis: #{data_ref}"
					end

 				}
			end

			# array
			if (line[6] == "MICROARRAY") && (line[11] && line[12] && line[13] && line[14])
				analyses_a.push([analysis_alias, study_ref, sample_ref_a, data_ref_a, line[4], line[5], line[6], line[7], line[8], line[9], line[10], line[11], line[12], line[13], line[14], line[15], "", "", "", "", line[20]])
			# variation
			elsif (line[6] == "SEQUENCE_VARIATION") && (line[16] && line[17] && line[18])
				analyses_a.push([analysis_alias, study_ref, sample_ref_a, data_ref_a, line[4], line[5], line[6], line[7], line[8], line[9], line[10], "", "", "", "", "", line[16], line[17], line[18], line[19], line[20]])
			# non-array
			else
				analyses_a.push([analysis_alias, study_ref, sample_ref_a, data_ref_a, line[4], line[5], line[6], line[7], line[8], line[9], line[10], "", "", "", "", "", "", "", "", "", line[20]])
			end

		end

	end

end

# Data set
datasets_a = Array.new
dataset_aliases_a = Array.new
for num, line in dataset_a
	if /^Dataset-\d{1,6}/ =~ line[0]

		# alias
		dataset_alias = submission_id + "_Dataset_" + sprintf("%06d", line[0].split("-")[1].to_i)
		dataset_aliases_a.push(dataset_alias)

		if line[4] && line[5]

			# DATA_REF
			data_ref_a = []
			if line[1]

 				line[1].split(",").each{|data_ref|

 					data_ref = data_ref.strip

					if data_ref =~ /Data-\d{1,}/
						data_ref = submission_id + "_Data_" + sprintf("%06d", data_ref.split("-")[1].to_i)
						data_ref_a.push(data_ref)
					elsif data_ref =~ /(JGAR|AGDR_)\d{9}/
						data_ref_a.push(data_ref)
					else
						raise "Invalid data ref from Dataset: #{data_ref}"
					end

 				}

			end

			# ANALYSIS_REF
			analysis_ref_a = []
			if line[2]

 				line[2].split(",").each{|analysis_ref|

 					analysis_ref = analysis_ref.strip

					if analysis_ref =~ /Analysis-\d{1,}/
						analysis_ref = submission_id + "_Analysis_" + sprintf("%06d", analysis_ref.split("-")[1].to_i)
						analysis_ref_a.push(analysis_ref)
					elsif analysis_ref =~ /(JGAZ|AGDZ_)\d{9}/
						analysis_ref_a.push(analysis_ref)
					else
						raise "Invalid analysis ref from Dataset: #{analysis_ref}"
					end
 				}

			end

			policy_ref = line[3]

			datasets_a.push([dataset_alias, data_ref_a, analysis_ref_a, policy_ref, line[4], line[5], line[6]])

		end

	end

end

# File
files_a = Array.new
checksums_a = Array.new
filenames_a = Array.new
files_h = Hash.new
i = 0 # array index number

for num, line in file_a

	if line[0] && line[1] && line[0] != "" && line[1].strip.gsub(/[[:space:]]/, '') =~ /^[a-f0-9]{32}$/i

		# md5
		filename = line[0].strip
		md5 = line[1].strip.gsub(/[[:space:]]/, '')

		files_h.store(filename, md5)
		files_a.push([filename, md5])
		checksums_a.push(md5)
		filenames_a.push(filename)

	end

end

# alias 重複チェック

sample_aliases_duplicated_a = sample_aliases_a.select{|e| sample_aliases_a.count(e) > 1 }.uniq
experiment_aliases_duplicated_a = experiment_aliases_a.select{|e| experiment_aliases_a.count(e) > 1 }.uniq
data_aliases_duplicated_a = data_aliases_a.select{|e| data_aliases_a.count(e) > 1 }.uniq
analyses_aliases_duplicated_a = analyses_aliases_a.select{|e| analyses_aliases_a.count(e) > 1 }.uniq
dataset_aliases_duplicated_a = dataset_aliases_a.select{|e| dataset_aliases_a.count(e) > 1 }.uniq

puts "Sample aliases duplication: #{sample_aliases_duplicated_a.join(",")}" if sample_aliases_duplicated_a.size > 0
puts "Expeirment aliases duplication: #{experiment_aliases_duplicated_a.join(",")}" if experiment_aliases_duplicated_a.size > 0
puts "Data aliases duplication: #{data_aliases_duplicated_a.join(",")}" if data_aliases_duplicated_a.size > 0
puts "Analysis aliases duplication: #{analyses_aliases_duplicated_a.join(",")}" if analyses_aliases_duplicated_a.size > 0
puts "Dataset aliases duplication: #{dataset_aliases_duplicated_a.join(",")}" if dataset_aliases_duplicated_a.size > 0

# objects into an array
metadata_a = [submission_a, study_a, sample_a, experiment_a, data_a, analysis_a, dataset_a]

### Create XML
prefix = submission_id + "_"

# Submission
xml_submission = Builder::XmlMarkup.new(:indent=>4)

submission_f = open(prefix + "Submission.xml", "w")
submission_f.puts instruction

# Study
xml_study = Builder::XmlMarkup.new(:indent=>4)

study_f = open(prefix + "Study.xml", "w")
study_f.puts instruction

# Sample
xml_sample = Builder::XmlMarkup.new(:indent=>4)

sample_f = open(prefix + "Sample.xml", "w")
sample_f.puts instruction

# Experiment
xml_experiment = Builder::XmlMarkup.new(:indent=>4)

experiment_f = open(prefix + "Experiment.xml", "w")
experiment_f.puts instruction

# Data
if not datas_a.empty?
	xml_data = Builder::XmlMarkup.new(:indent=>4)

	data_f = open(prefix + "Data.xml", "w")
	data_f.puts instruction
end

# Analysis
if not analyses_a.empty?
	xml_analysis = Builder::XmlMarkup.new(:indent=>4)

	analysis_f = open(prefix + "Analysis.xml", "w")
	analysis_f.puts instruction
end

# Data set
xml_dataset = Builder::XmlMarkup.new(:indent=>4)

dataset_f = open(prefix + "Dataset.xml", "w")
dataset_f.puts instruction

# submission date
submission_date = submission_h["submission_date"]
center_name = submission_h["center_name"]

submission_f.puts xml_submission.SUBMISSION("accession" => "", "center_name" => center_name, "alias" => submission_h["alias"], "lab_name" => submission_h["organization"], "submission_date" => submission_date, "nbdc_number" => submission_h["nbdc_number"]) {|submission|

	submission.CONTACTS{|contacts|
		for contact in submission_h["contacts"]
			contacts.CONTACT("inform_on_error" => contact[2], "inform_on_status" => contact[2], "name" => "#{contact[0]} #{contact[1]}")
		end
	}

	if submission_h["hold"] == "Hold"
		submission.ACTIONS{|actions|
			actions.ACTION{|action|
				action.HOLD
			}
		}
	end

}

# Study
study_f.puts xml_study.STUDY_SET{|study_set|

	study_set.STUDY("accession" => "", "center_name" => center_name, "alias" => submission_id + "_Study_000001"){|study|

		study.DESCRIPTOR{|descriptor|
			descriptor.STUDY_TITLE(study_h["Title"])

			descriptor.STUDY_TYPES{|study_types|

				for study_type in study_h["study_type"]

					# If there is a new study type.
					if study_type[1]
						study_types.STUDY_TYPE("existing_study_type" => "Other", "new_study_type" => study_type[1])
					elsif study_type[0]
						study_types.STUDY_TYPE("existing_study_type" => study_type[0])
					end

				end

			}

			descriptor.STUDY_ABSTRACT(study_h["Abstract"])

		}

		if study_h["grant"].size > 0
			study.GRANTS{|grants|
				for grant_array in study_h["grant"]
					# Needs Title and (Agency or Agency Abbreviation).
					if grant_array[0] && (grant_array[1] || grant_array[2])

						# empty if no grant id.
						if grant_array[3].nil?
							grant_array[3] = ""
						else
							grant_array[3] = grant_array[3]#.to_i
						end

						# grant
						grants.GRANT("grant_id" => grant_array[3]){|grant|
							grant.TITLE(grant_array[0])
							grant.AGENCY(grant_array[1], "abbr" => grant_array[2])
						}
					end
				end
			}
		end

		if study_h["publication"].size > 0
			study.PUBLICATIONS{|publications|
				for publication in study_h["publication"]
					# pubmed id
					if publication[0] && /\d+/ =~ publication[0].to_i.to_s
						publications.PUBLICATION("id" => publication[0].to_i.to_s, "status" => "published"){|publication|
							publication.DB_TYPE("PUBMED")
						}
					end
				end
			}
		end

		if study_h["link"].size > 0
			study.STUDY_LINKS{|study_links|
				for link_array in study_h["link"]
					study_links.STUDY_LINK{|study_link|
						study_link.URL_LINK{|url_link|
							url_link.LABEL(link_array)
							url_link.URL(link_array)
						}
					}
				end
			}
		end

		# Output the submission content to attributes
		study.STUDY_ATTRIBUTES{|study_attributes|
			study_attributes.STUDY_ATTRIBUTE{|study_attribute|
				study_attribute.TAG("NBDC Number")
				study_attribute.VALUE(submission_h["nbdc_number"])
			}
			study_attributes.STUDY_ATTRIBUTE{|study_attribute|
				study_attribute.TAG("Registration date")
				study_attribute.VALUE(submission_date.sub(/T.*/, ""))
			}

			# Extract PI information
			if submission_h["pi"]
				for first_name, last_name, mail, tel, organization in submission_h["pi"]
					# organization
					study_attributes.STUDY_ATTRIBUTE{|study_attribute|
						study_attribute.TAG("Submitting organization")
						study_attribute.VALUE(organization)
					}

					# PI name
					study_attributes.STUDY_ATTRIBUTE{|study_attribute|
						study_attribute.TAG("Principal Investigator")
						study_attribute.VALUE("#{first_name} #{last_name}")
					}

				end
			end

			# molecular_data_type
			if study_h["molecular_data_type"]
				for type, platform, vendor, comment in study_h["molecular_data_type"]

					# molecular_data_type
					study_attributes.STUDY_ATTRIBUTE{|study_attribute|
						study_attribute.TAG("Molecular Data Type")
						study_attribute.VALUE(type)
					}

					study_attributes.STUDY_ATTRIBUTE{|study_attribute|
						study_attribute.TAG("Platform")
						study_attribute.VALUE(platform)
					}

					study_attributes.STUDY_ATTRIBUTE{|study_attribute|
						study_attribute.TAG("Vendor")
						study_attribute.VALUE(vendor)
					}

					study_attributes.STUDY_ATTRIBUTE{|study_attribute|
						study_attribute.TAG("Comment")
						study_attribute.VALUE(comment)
					}

				end
			end

			# phenotype terms
			if study_h["phenotype_disease_terms"]
				first = true
				for phenotype_disease_term in study_h["phenotype_disease_terms"]

					if first
						# primary phenotype term
						study_attributes.STUDY_ATTRIBUTE{|study_attribute|
							study_attribute.TAG("Primary Phenotype")
							study_attribute.VALUE(phenotype_disease_term)
						}
						first = false
					else
						# phenotype term
						study_attributes.STUDY_ATTRIBUTE{|study_attribute|
							study_attribute.TAG("Phenotype")
							study_attribute.VALUE(phenotype_disease_term)
						}
					end

				end
			end

			# Inclusion/Exclusion Criteria
			if study_h["inclusion_exclusion_criteria"]

				# Inclusion/Exclusion Criteria
				study_attributes.STUDY_ATTRIBUTE{|study_attribute|
					study_attribute.TAG("Study Inclusion/Exclusion Criteria")
					study_attribute.VALUE(study_h["inclusion_exclusion_criteria"])
				}

			end

			# disease type
			if study_h["disease_classification"]

				# disease type
				for disease_classification, code in study_h["disease_classification"]
					study_attributes.STUDY_ATTRIBUTE{|study_attribute|
						study_attribute.TAG("ICD-10 Disease Classification")
						if code
							study_attribute.VALUE("#{disease_classification} (#{code})")
						else
							study_attribute.VALUE("#{disease_classification}")
						end
					}
				end

			end

			# Output the study content to attributes.
			if study_h["attribute"] && study_h["attribute"].size > 0
					for attribute in study_h["attribute"]
						# if there are tag and value
						if attribute[0] && attribute[1]
							study_attributes.STUDY_ATTRIBUTE{|study_attribute|
								study_attribute.TAG(attribute[0])
								study_attribute.VALUE(attribute[1])
							}
						end
					end
			end

		}

	}
}

# Sample
sample_f.puts xml_sample.SAMPLE_SET{|sample_set|

	for sam in samples_a
		sample_set.SAMPLE("accession" => "", "center_name" => center_name, "alias" => sam[0]){|sample|
			sample.TITLE(sam[4])
			sample.SAMPLE_NAME{|sample_name|

				sample_name.TAXON_ID("9606")
				sample_name.SCIENTIFIC_NAME("Homo sapiens")
				sample_name.COMMON_NAME("Human")

				sample_name.DONOR_ID(sam[2])

			}

			sample.SAMPLE_GROUP_TYPE(sam[6])
			sample.DESCRIPTION(sam[5])

			# attributes
			sample.SAMPLE_ATTRIBUTES{|sample_attributes|

				# sample name required
				sample_attributes.SAMPLE_ATTRIBUTE{|sample_attribute|
					sample_attribute.TAG("sample_name")
					sample_attribute.VALUE(sam[1].to_s.strip)
				}

				# gender
				if sam[3]
					sample_attributes.SAMPLE_ATTRIBUTE{|sample_attribute|
						sample_attribute.TAG("gender")
						sample_attribute.VALUE(sam[3].strip)

						first = false
					}
				end

				# affection status
				if sam[6]
					sample_attributes.SAMPLE_ATTRIBUTE{|sample_attribute|
						sample_attribute.TAG("affection_status")
						sample_attribute.VALUE(sam[6].strip)
					}
				end

				# tissue
				if sam[7]
					sample_attributes.SAMPLE_ATTRIBUTE{|sample_attribute|
						sample_attribute.TAG("tissue")
						sample_attribute.VALUE(sam[7])
					}
				end

				# population
				if sam[8]
					sample_attributes.SAMPLE_ATTRIBUTE{|sample_attribute|
						sample_attribute.TAG("population")
						sample_attribute.VALUE(sam[8])
					}
				end

				# histological_type
				if sam[9]
					sample_attributes.SAMPLE_ATTRIBUTE{|sample_attribute|
						sample_attribute.TAG("histological_type")
						sample_attribute.VALUE(sam[9])
					}
				end

				# is_tumor
				if sam[10]
					sample_attributes.SAMPLE_ATTRIBUTE{|sample_attribute|
						sample_attribute.TAG("is_tumor")
						sample_attribute.VALUE(sam[10])
					}
				end

				# phenotypes
				if sam[11] && sam[11].split(";")

					sam[11].split(";").each{|phenotype|
						sample_attributes.SAMPLE_ATTRIBUTE{|sample_attribute|
							pp phenotype if phenotype.strip.split(":")[0].nil?

							sample_attribute.TAG(phenotype.strip.split(":")[0].strip)
							sample_attribute.VALUE(phenotype.strip.split(":")[1].strip)
						}
					}

				end

			}

		}

	end

}

# Experiment
experiment_f.puts xml_experiment.EXPERIMENT_SET{|experiment_set|

	for exp in experiments_a

		experiment_set.EXPERIMENT("accession" => "", "center_name" => center_name, "alias" => exp[0]){|experiment|
			experiment.TITLE(exp[2])

			if study_accession =~ /(JGAS|AGDS_)\d{6}/
				experiment.STUDY_REF("accession" => study_accession, "refcenter" => center_name, "refname" => study_accession)
			else
				experiment.STUDY_REF("accession" => "", "refcenter" => center_name, "refname" => submission_id + "_Study_000001")
			end

			if exp[1] =~ /_Sample_\d{4}/
				experiment.SAMPLE_REF("accession" => "", "refcenter" => center_name, "refname" => exp[1])
			elsif exp[1] =~ /(JGAN|AGDN_)\d{9}/
				experiment.SAMPLE_REF("accession" => exp[1], "refcenter" => center_name, "refname" => exp[1])
			end

			experiment.DESIGN{|design|

				design.DESIGN_DESCRIPTION(exp[3])

				design.LIBRARY_DESCRIPTOR{|lib_des|
					lib_des.LIBRARY_NAME(exp[4])

					lib_des.LIBRARY_STRATEGY{|lib_strategy|
						lib_strategy.SEQUENCING_LIBRARY_STRATEGY(exp[8])
					}

					design.LIBRARY_SOURCE(exp[5])
					design.LIBRARY_SELECTION(exp[6])

					# NGS
					design.LIBRARY_LAYOUT{|layout|
						if exp[10] == "PAIRED" && exp[11] && exp[12]
							layout.PAIRED("nominal_length" => exp[11].to_i, "nominal_sdev" => exp[12])
						elsif  exp[10] == "PAIRED" && exp[11]
							layout.PAIRED("nominal_length" => exp[11].to_i)
						elsif  exp[10] == "PAIRED" && exp[12]
							layout.PAIRED("nominal_sdev" => exp[12])
						elsif  exp[10] == "PAIRED"
							layout.PAIRED()
						else
							layout.SINGLE
						end
					} # layout

					design.LIBRARY_CONSTRUCTION_PROTOCOL(exp[9])

				} # lib_des

				design.SPOT_DESCRIPTOR{|spot_des|
					spot_des.SPOT_DECODE_SPEC{|decode|
						decode.READ_SPEC{|spec|
							spec.READ_INDEX("0")
							spec.READ_CLASS("Application Read")
							spec.READ_TYPE("Forward")
							spec.BASE_COORD("1")
						} # spec
						if exp[10] == "PAIRED"
							decode.READ_SPEC{|spec|
								spec.READ_INDEX("1")
								spec.READ_CLASS("Application Read")
								spec.READ_TYPE(exp[15])
								spec.BASE_COORD(exp[16])
							} # spec
						end

					} # decode
				} # spot_des

			} # design

			experiment.PLATFORM{|platform|

				# NGS
				platform.SEQUENCING_PLATFORM{|seq_platform|

					seq_platform.SEQUENCING_PLATFORM{|seq2_platform|

						case exp[7]

						when /454/i
							seq2_platform.LS454{|platform_e|
								platform_e.INSTRUMENT_MODEL(exp[7])
							}

						when /illumina|NextSeq|HiSeq/i
							seq2_platform.ILLUMINA{|platform_e|
								platform_e.INSTRUMENT_MODEL(exp[7])
							}

						when /solid/i
							seq2_platform.ABI_SOLID{|platform_e|
								platform_e.INSTRUMENT_MODEL(exp[7])
							}

						when /Ion/
							seq2_platform.ION_TORRENT{|platform_e|
								platform_e.INSTRUMENT_MODEL(exp[7])
							}

						when /pacbio|sequel/i
							seq2_platform.PACBIO_SMRT{|platform_e|
								platform_e.INSTRUMENT_MODEL(exp[7])
							}

						when /ION/
							seq2_platform.OXFORD_NANOPORE{|platform_e|
								platform_e.INSTRUMENT_MODEL(exp[7])
							}

						when /bgiseq|dnbseq|mgiseq/i
							seq2_platform.BGISEQ{|platform_e|
								platform_e.INSTRUMENT_MODEL(exp[7])
							}

						end

						} #seq2_platform

					} #seq_platform

			} # platform

		} # exp

	end

}

# Data
data_files_a = []
if not datas_a.empty?

	data_f.puts xml_data.DATA_CONTAINER{|data_container|

		for data in datas_a

			data_container.DATA("accession" => "", "center_name" => center_name, "alias" => data[0]){|data_e|

				if data[1] =~ /_Experiment_\d{4,6}/
					data_e.EXPERIMENT_REF("accession" => "", "refcenter" => center_name, "refname" => data[1])
				elsif data[1] =~ /(JGAX|AGDX_)\d{9}/
					data_e.EXPERIMENT_REF("accession" => data[1], "refcenter" => center_name, "refname" => data[1])
				end

				# Data type
				case data[-1]

				# ngs
				when "data_ngs"

					# filetype is bam
					if data[3] == "bam" && ( data[4] || data[5] )
						data_e.DATA_TYPE{|data_type|
							data_type.REFERENCE_ALIGNMENT{|alignment|
								alignment.SEQUENCE("refname" => data[4], "accession" => data[5])
							}
						}

					# not bam
					elsif data[3] != "bam"
						data_e.DATA_TYPE{|data_type|
							data_type.SEQUENCING
						}
					end

				end

				data_e.DATA_BLOCK{|block|

					block.FILES{|files|

						if data[2] && data[2].include?(",")

							for filename in data[2].split(/,\s*/)

								# spaces in filename
								raise "Filename contains space: #{filename}" if filename.include?(" ")

								filename = filename.strip.gsub("\n", "")
								data_files_a.push(filename) unless filename.empty?

								unless filename.empty?

									md5 = ""
									if files_h[filename]
										md5 = files_h[filename]
										# md5 to lowercase, no differences between upper and lower but the JGA system uses lowercase.
										md5 = md5.downcase
									end

									if /fastq/ =~ data[3]
										files.FILE("checksum" => "", "unencrypted_checksum" => md5, "checksum_method" => "MD5", "ascii_offset" => "!", "quality_encoding" => "ascii", "quality_scoring_system" => "phred", "filetype" => data[3], "filename" => filename)
									else
										files.FILE("checksum" => "", "unencrypted_checksum" => md5, "checksum_method" => "MD5", "filetype" => data[3], "filename" => filename)
									end
								end

							end

						else

							filename = data[2].strip.gsub("\n", "") unless data[2].empty?
							data_files_a.push(filename) unless filename.empty?

							unless filename.empty?

								md5 = ""
								if files_h[filename]
									md5 = files_h[filename]
									# md5 to lowercase, no differences between upper and lower but the JGA system uses lowercase.
									md5 = md5.downcase
								end

								if /fastq/ =~ data[3]
									files.FILE("checksum" => "", "unencrypted_checksum" => md5, "checksum_method" => "MD5", "ascii_offset" => "!", "quality_encoding" => "ascii", "quality_scoring_system" => "phred", "filetype" => data[3], "filename" => filename)
								else
									files.FILE("checksum" => "", "unencrypted_checksum" => md5, "checksum_method" => "MD5", "filetype" => data[3], "filename" => filename)
								end
							end

						end

					} # files

				} # block

			} # data_e

		end # for

	} # data_container

end

# filename uniqueness
data_files_duplicated_a = data_files_a.select{|e| data_files_a.index(e) != data_files_a.rindex(e)}
raise "Files #{data_files_duplicated_a.join("\n")}: duplicated in Data XML" unless data_files_duplicated_a.empty?

# Analysis
analysis_files_a = []
if not analyses_a.empty?
	analysis_f.puts xml_analysis.ANALYSIS_SET{|analysis_set|

		for ana in analyses_a

			# attributes analysis_center
			analysis_center = ""
			analysis_date = ""
			if ana[20] && ana[20].split(";")
				ana[20].split(";").each{|attribute|
					if attribute.strip.split(/:(?!\/)/)[0].strip == "analysis_center"
						analysis_center = attribute.strip.split(/:(?!\/)/)[1].strip
					end
					if attribute.strip.split(/:(?!\/)/)[0].strip == "analysis_date"
						analysis_date = attribute.strip.split(/:(?!\/)/)[1].strip
						analysis_date = "#{analysis_date}T12:00:00"
					end
				}
			end

			# analysis_date and analysis_center
			attributes_h = {"accession" => "", "center_name" => center_name, "alias" => ana[0]}
			if analysis_date != "" && analysis_center != ""
				attributes_h.store("analysis_date", analysis_date)
				attributes_h.store("analysis_center", analysis_center)
			elsif analysis_date != "" && analysis_center == ""
				attributes_h.store("analysis_date", analysis_date)
			elsif analysis_date == "" && analysis_center != ""
				attributes_h.store("analysis_center", analysis_center)
			end

			analysis_set.ANALYSIS(options = attributes_h){|analysis_e|

				analysis_e.TITLE(ana[4])
				analysis_e.DESCRIPTION(ana[5])

				if ana[1] =~ /^#{submission_id}_Study_\d{4,6}$/
					analysis_e.STUDY_REFS{|study_refs|
						study_refs.STUDY_REF("accession" => "", "refcenter" => center_name, "refname" => ana[1])
					}
				elsif ana[1] =~ /^(JGAS|AGDS_)\d{6}$/
					analysis_e.STUDY_REFS{|study_refs|
						study_refs.STUDY_REF("accession" => ana[1], "refcenter" => center_name, "refname" => ana[1])
					}
				end

				if ana[2].size > 0
					analysis_e.SAMPLE_REFS{|sample_refs|
						ana[2].each{|ref|
							if ref =~ /^#{submission_id}_Sample_\d{4,6}$/
								sample_refs.SAMPLE_REF("accession" => "", "refcenter" => center_name, "refname" => ref)
							elsif ref =~ /^(JGAN|AGDN_)\d{9}$/
								sample_refs.SAMPLE_REF("accession" => ref, "refcenter" => center_name, "refname" => ref)
							else
								raise "Invalid sample ref from Dataset: #{ref}"
							end
						}
					}
				end

				if ana[3].size > 0
					analysis_e.DATA_REFS{|data_refs|
						ana[3].each{|ref|
							if ref =~ /^#{submission_id}_Data_\d{4,6}$/
								data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => ref)
							elsif ref =~ /^(JGAR|AGDR_)\d{9}$/
								data_refs.DATA_REF("accession" => ref, "refcenter" => center_name, "refname" => ref)
							else
								raise "Invalid data ref from Dataset: #{ref}"
							end
						}
					}
				end

				analysis_e.ANALYSIS_TYPE{|analysis_type|
					case ana[6].strip

					when "ABUNDANCE_MEASUREMENT"
						analysis_type.ABUNDANCE_MEASUREMENT

					when "REFERENCE_ALIGNMENT"
						analysis_type.REFERENCE_ALIGNMENT{|reference_alignment|

						# if specified by refname
						if ana[9] || ana[10]

							reference_alignment.ASSEMBLY{|assembly|
								if ana[9] && ana[10]
									assembly.STANDARD("refname" => ana[9], "accession" => ana[10])
								elsif ana[9]
									assembly.STANDARD("refname" => ana[9])
								elsif ana[10]
									assembly.STANDARD("accession" => ana[10])
								end
							}

						end

						}

					when "SEQUENCE_VARIATION"
						analysis_type.SEQUENCE_VARIATION{|sequence_variation|

							# if specified by refname
							if ana[9] || ana[10]

								sequence_variation.ASSEMBLY{|assembly|
									if ana[9] && ana[10]
										assembly.STANDARD("refname" => ana[9], "accession" => ana[10])
									elsif ana[9]
										assembly.STANDARD("refname" => ana[9])
									elsif ana[10]
										assembly.STANDARD("accession" => ana[10])
									end
								}

							end

							# experiment type
							if ana[16]
								sequence_variation.EXPERIMENT_TYPE(ana[16])
							end

							# program
							if ana[18]
								sequence_variation.PROGRAM(ana[18])
							end

							# platform
							if ana[17]
								sequence_variation.PLATFORM(ana[17])
							end

							# imputation
							if ana[19]
								sequence_variation.IMPUTATION("true")
							end

						} # sequence_variation

					when "SEQUENCE_ASSEMBLY"
						analysis_type.SEQUENCE_ASSEMBLY

					when "SEQUENCE_ANNOTATION"
						analysis_type.SEQUENCE_ANNOTATION

					when "REFERENCE_SEQUENCE"
						analysis_type.REFERENCE_SEQUENCE

					when "SAMPLE_PHENOTYPE"
						analysis_type.SAMPLE_PHENOTYPE

					when "MICROARRAY"

						# array
						if ana[11] && ana[12] && ana[13] && ana[14]

							analysis_type.MICROARRAY{|microarray|

								microarray.EXPERIMENT_TYPE(ana[11])

								microarray.PLATFORM(ana[12]) if ana[12]
								microarray.PLATFORM_VENDOR(ana[13]) if ana[13]
								microarray.PLATFORM_DESCRIPTION(ana[14]) if ana[14]
								microarray.PROGRAM(ana[15]) if ana[15]

							} # analysis_type.MICROARRAY

						end

					when "METABOLOMICS"
						analysis_type.METABOLOMICS

					when "PROTEOMICS"
						analysis_type.PROTEOMICS

					when "BIOCHEMICAL_ASSAY"
						analysis_type.BIOCHEMICAL_ASSAY

					when "IMAGE"
						analysis_type.IMAGE

					when "DOCUMENT"
						analysis_type.DOCUMENT

					when "OTHER"
						analysis_type.OTHER

					end

				}

				analysis_e.FILES{|files|

					# file name and type listed by separated by comma.
					# both are not listed.
					if ana[7].split(/,\s*/).size == 1 && ana[8].split(/,\s*/).size == 1

						filename = ana[7]

						# spaces in filename
						raise "Filename contains space: #{filename}" if filename.include?(" ")
						# compression format
						raise "File is archived by zip: #{filename}" if filename =~ /\.zip$/

						analysis_files_a.push(filename)

						md5 = ""
						if files_h[filename]
							md5 = files_h[filename]
							# md5 to lowercase, no differences between upper and lower but the JGA system uses lowercase.
							md5 = md5.downcase
						end

						files.FILE("checksum" => "", "unencrypted_checksum" => md5,  "checksum_method" => "MD5", "filetype" => ana[8], "filename" => filename)

					# list name only
					elsif ana[7].split(/,\s*/).size > 1 && ana[8].split(/,\s*/).size == 1

						for filename in ana[7].split(/,\s*/)

							# spaces in filename
							raise "Filename contains space: #{filename}" if filename.include?(" ")
							# compression format
							raise "File is archived by zip: #{filename}" if filename =~ /\.zip$/

							analysis_files_a.push(filename)

							md5 = ""
							if files_h[filename]
								md5 = files_h[filename]
								# md5 to lowercase, no differences between upper and lower but the JGA system uses lowercase.
								md5 = md5.downcase
							end

							files.FILE("checksum" => "", "unencrypted_checksum" => md5,  "checksum_method" => "MD5", "filetype" => ana[8], "filename" => filename)

						end

					# list name and type
					elsif ana[7].split(/,\s*/).size > 1 && ana[8].split(/,\s*/).size > 1

						raise "Error: numbers of filenames and filetypes are different." if ana[7].split(/,\s*/).size != ana[8].split(/,\s*/).size

						m = 0
						for filename in ana[7].split(/,\s*/)

							# spaces in filename
							raise "Filename contains space: #{filename}" if filename.include?(" ")
							# compression format
							raise "File is archived by zip: #{filename}" if filename =~ /\.zip$/

							analysis_files_a.push(filename)

							md5 = ""
							if files_h[filename]
								md5 = files_h[filename]
								# md5 to lowercase, no differences between upper and lower but the JGA system uses lowercase.
								md5 = md5.downcase
							end

							filetypes_a = ana[8].split(/,\s*/)
							files.FILE("checksum" => "", "unencrypted_checksum" => md5,  "checksum_method" => "MD5", "filetype" => filetypes_a[m], "filename" => filename)

							m = m + 1

						end

					# list type only
					else
						raise "Error: only filetypes are listed."
					end

				} # analysis_e.FILES{|files|

				# attributes
				if ana[20] && ana[20].split(";")

					analysis_e.ANALYSIS_ATTRIBUTES{|analysis_attributes|

						ana[20].split(";").each{|attribute|
							analysis_attributes.ANALYSIS_ATTRIBUTE{|analysis_attribute|
								analysis_attribute.TAG(attribute.strip.split(/:(?!\/)/)[0].strip)
								analysis_attribute.VALUE(attribute.strip.split(/:(?!\/)/)[1].strip)
							}
						}

					}

				end

			}

		end

	}
end

# filename uniqueness
analysis_files_duplicated_a = analysis_files_a.select{|e| analysis_files_a.index(e) != analysis_files_a.rindex(e)}
raise "Files #{analysis_files_duplicated_a.join("\n")}: duplicated in Analysis XML" unless analysis_files_duplicated_a.empty?

# filename uniqueness across Data and Analysis
combined_files_duplicated_a = data_files_duplicated_a + analysis_files_duplicated_a
raise "Files #{combined_files_duplicated_a.join("\n")}: duplicated between Data and Analysis XML" unless combined_files_duplicated_a.empty?

# Data set
if not datasets_a.empty?

	dataset_f.puts xml_dataset.DATASETS{|dataset_set|

		for dataset in datasets_a

			dataset_set.DATASET("accession" => "", "center_name" => center_name, "alias" => dataset[0]){|dataset_e|

				dataset_e.TITLE(dataset[4])
				dataset_e.DESCRIPTION(dataset[5])

				dataset_e.DATASET_TYPE(dataset[6].strip) if dataset[6]

				# Single policy is associated with a data set.
				if dataset[1].empty? && dataset[2].empty?

					# A default NBDC policy is associated. JGA
					if (dataset[3].nil? || dataset[3] == "JGAP000001") && submission_id =~ /^JSUB\d{6}$/

						dataset_e.DATA_REFS{|data_refs|
							for data in datas_a
								data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => data[0])
							end
						}

						dataset_e.ANALYSIS_REFS{|analysis_refs|
							for ana in analyses_a
								analysis_refs.ANALYSIS_REF("accession" => "", "refcenter" => center_name, "refname" => ana[0])
							end
						}

						dataset_e.POLICY_REF("accession" => "JGAP000001", "refcenter" => "nbdc", "refname" => "JGAP000001")

					# A submitter's policy approved by NBDC is associated.
					elsif dataset[3] && /^JGAP\d{6}$/ =~ dataset[3] && dataset[3] != "JGAP000001"

						dataset_e.DATA_REFS{|data_refs|
							for data in datas_a
								data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => data[0])
							end
						}

						dataset_e.ANALYSIS_REFS{|analysis_refs|
							for ana in analyses_a
								analysis_refs.ANALYSIS_REF("accession" => "", "refcenter" => center_name, "refname" => ana[0])
							end
						}

						dataset_e.POLICY_REF("accession" => dataset[3], "refcenter" => "nbdc", "refname" => dataset[3])

					# AGD default
					elsif (dataset[3].nil? || dataset[3] == "AGDP_000001") && submission_id =~ /^ASUB\d{6}$/

						dataset_e.DATA_REFS{|data_refs|
							for data in datas_a
								data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => data[0])
							end
						}

						dataset_e.ANALYSIS_REFS{|analysis_refs|
							for ana in analyses_a
								analysis_refs.ANALYSIS_REF("accession" => "", "refcenter" => center_name, "refname" => ana[0])
							end
						}

						dataset_e.POLICY_REF("accession" => "AGDP_000001", "refcenter" => "nbdc", "refname" => dataset[3])

					# AGD original policy
					elsif dataset[3] && /^AGDP_\d{6}$/ =~ dataset[3] && dataset[3] != "AGDP_000001"

						dataset_e.DATA_REFS{|data_refs|
							for data in datas_a
								data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => data[0])
							end
						}

						dataset_e.ANALYSIS_REFS{|analysis_refs|
							for ana in analyses_a
								analysis_refs.ANALYSIS_REF("accession" => "", "refcenter" => center_name, "refname" => ana[0])
							end
						}

						dataset_e.POLICY_REF("accession" => dataset[3], "refcenter" => "nbdc", "refname" => dataset[3])

					end

				# Data/Analysis refs are set for this data set.
				else

					if dataset[1].size > 0
						dataset_e.DATA_REFS{|data_refs|
							dataset[1].each{|ref|
								if ref =~ /_Data_\d{4,6}/
									data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => ref)
								elsif ref =~ /(JGAR|AGDR_)\d{9}/
									data_refs.DATA_REF("accession" => ref, "refcenter" => center_name, "refname" => ref)
								else
									raise "Invalid data ref from Dataset: #{ref}"
								end
							}
						}
					end

					if dataset[2].size > 0
						dataset_e.ANALYSIS_REFS{|analysis_refs|
							dataset[2].each{|ref|
								if ref =~ /_Analysis_\d{4,6}/
									analysis_refs.ANALYSIS_REF("accession" => "", "refcenter" => center_name, "refname" => ref)
								elsif ref =~ /(JGAZ|AGDZ_)\d{9}/
									analysis_refs.ANALYSIS_REF("accession" => ref, "refcenter" => center_name, "refname" => ref)
								else
									raise "Invalid analysis ref from Dataset: #{ref}"
								end
							}
						}
					end

					# A default NBDC policy is associated. JGA
					if (dataset[3].nil? || dataset[3] == "JGAP000001") && submission_id =~ /^JSUB\d{6}$/
						dataset_e.POLICY_REF("accession" => "JGAP000001", "refcenter" => "nbdc", "refname" => "JGAP000001")
					# A submitter's policy approved by NBDC is associated.
					elsif dataset[3] && /^JGAP\d{6}$/ =~ dataset[3] && dataset[3] != "JGAP000001"
						dataset_e.POLICY_REF("accession" => dataset[3], "refcenter" => "nbdc", "refname" => dataset[3])
					# AGD default
					elsif (dataset[3].nil? || dataset[3] == "AGDP_000001") && submission_id =~ /^ASUB\d{6}$/
						dataset_e.POLICY_REF("accession" => "AGDP_000001", "refcenter" => "nbdc", "refname" => dataset[3])
					# AGD original policy
					elsif dataset[3] && /^AGDP_\d{6}$/ =~ dataset[3] && dataset[3] != "AGDP_000001"
						dataset_e.POLICY_REF("accession" => dataset[3], "refcenter" => "nbdc", "refname" => dataset[3])
					end

				end
			}

		end

	}

# Data set
# if not datasets_a.empty?
else

	dataset_f.puts xml_dataset.DATASETS{|dataset_set|

		dataset_set.DATASET("accession" => "", "center_name" => center_name, "alias" => submission_id + "_Dataset_000001"){|dataset_e|

			dataset_e.TITLE(dataset[4])
			dataset_e.DESCRIPTION(dataset[5])

			dataset_e.DATASET_TYPE(dataset[6].strip) if dataset[6]

			# only the NBDC guideline is associated to a dataset.
			if dataset[1].empty? && dataset[2].empty? && dataset[3].nil? && policies_a.empty?

				dataset_e.DATA_REFS{|data_refs|
					for data in datas_a
						data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => data[0])
					end
				}

				dataset_e.ANALYSIS_REFS{|analysis_refs|
					for ana in analyses_a
						analysis_refs.ANALYSIS_REF("accession" => "", "refcenter" => center_name, "refname" => ana[0])
					end
				}

				if submission_id =~ /^JSUB\d{6}$/
					dataset_e.POLICY_REF("accession" => "JGAP000001", "refcenter" => "nbdc", "refname" => "JGAP000001")
				elsif submission_id =~ /^ASUB\d{6}$/
					dataset_e.POLICY_REF("accession" => "AGDP_000001", "refcenter" => "nbdc", "refname" => "AGDP_000001")
				end

			# only a submitter's policy is associated to a dataset.
			elsif dataset[1].empty? && dataset[2].empty? && dataset[3] && !policies_a.empty?

				dataset_e.DATA_REFS{|data_refs|
					for data in datas_a
						data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => data[0])
					end
				}

				dataset_e.ANALYSIS_REFS{|analysis_refs|
					for ana in analyses_a
						analysis_refs.ANALYSIS_REF("accession" => "", "refcenter" => center_name, "refname" => ana[0])
					end
				}

				ref = submission_id + "_Policy_" + sprintf("%06d", policy_ref.strip.split("-")[1].to_i)
				dataset_e.POLICY_REF("accession" => "", "refcenter" => "nbdc", "refname" => ref)

			# refs are set for this data set.
			else

				if dataset[1].size > 0
					dataset_e.DATA_REFS{|data_refs|
						dataset[1].each{|ref|
							if ref =~ /_Data_\d{4,6}/
								data_refs.DATA_REF("accession" => "", "refcenter" => center_name, "refname" => ref)
							elsif ref =~ /(JGAR|AGDR_)\d{9}/
								data_refs.DATA_REF("accession" => ref, "refcenter" => center_name, "refname" => ref)
							else
								raise "Invalid data ref from Dataset: #{ref}"
							end
						}
					}
				end

				if dataset[2].size > 0
					dataset_e.ANALYSIS_REFS{|analysis_refs|
						dataset[2].each{|ref|
							if ref =~ /_Analysis_\d{4,6}/
								analysis_refs.ANALYSIS_REF("accession" => "", "refcenter" => center_name, "refname" => ref)
							elsif ref =~ /(JGAZ|AGDZ_)\d{9}/
								analysis_refs.ANALYSIS_REF("accession" => ref, "refcenter" => center_name, "refname" => ref)
							else
								raise "Invalid analysis ref from Dataset: #{ref}"
							end
						}
					}
				end

				if dataset[3]
					ref = dataset[3]
					dataset_e.POLICY_REF("accession" => ref, "refcenter" => "nbdc", "refname" => "")
				end

			end

		}

	}

end

# filename duplication check
duplicated_data_files_a = []
duplicated_data_files_a = data_files_a.select{|e| data_files_a.index(e) != data_files_a.rindex(e)}
if duplicated_data_files_a.size > 0
	raise "#{duplicated_data_files_a.sort.uniq.join(",")} data files are duplicated"
end

duplicated_analysis_files_a = []
duplicated_analysis_files_a = analysis_files_a.select{|e| analysis_files_a.index(e) != analysis_files_a.rindex(e)}
if duplicated_analysis_files_a.size > 0
	raise "#{duplicated_analysis_files_a.sort.uniq.join(",")} analysis files are duplicated"
end

## md5 list check
# filename duplication check
duplicated_files_a = []
duplicated_files_a = filenames_a.select{|e| filenames_a.index(e) != filenames_a.rindex(e)}
if duplicated_files_a.size > 0
	raise "#{duplicated_files_a.sort.uniq.join(",")} filenames in filelist are duplicated"
end

# checksum duplication check
duplicated_checksums_a = []
duplicated_checksums_a = checksums_a.select{|e| checksums_a.index(e) != checksums_a.rindex(e)}

# Identical with files in Data and Analysis?
data_analysis_files_a = []
data_analysis_files_a = data_files_a + analysis_files_a

if (filenames_a - data_analysis_files_a).size > 0
	puts "Some files in filelist are not in Data and Analysis: #{(filenames_a - data_analysis_files_a).sort.uniq.join(",")}"
elsif (data_analysis_files_a - filenames_a).size > 0
	puts "Some files in Data and Analysis are not in filelist: #{(data_analysis_files_a - filenames_a).sort.uniq.join(",")}"
else (data_analysis_files_a - filenames_a).size == 0
	puts "Files in filelist and those of Data and Analysis are identical."
end




