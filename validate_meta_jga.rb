#! /usr/bin/ruby
# -*- coding: utf-8 -*-

require 'rexml/document'
require 'optparse'

#
# Bioinformation and DDBJ Center
# Japanese Genotype-phenotype Archive
#

# Update history
# 2022-12-21 Check duplicated references from Datasets to Data and Analysis
# 2022-12-14 publicly released

### Options
account = ""
submission_id = ""
OptionParser.new{|opt|

	opt.on('-j [JSUB ID]', 'JSUB submission ID'){|v|
		raise "usage: -j JGA submission ID (JSUB000001)" if v.nil? || !(/^JSUB\d{6}$/ =~ v)
		submission_id = v
		puts "JGA Submission ID: #{v}"
	}

	begin
		opt.parse!
	rescue
		puts "Invalid option. #{opt}"
	end

}

# metadata objects
meta_object = ['Submission', 'Study', 'Sample', 'Experiment', 'Data', 'Analysis', 'Dataset', 'Policy', 'Dac']

##
## Validate JGA XML files against JGA xsd and check relations.
##

## Validate XMLs against JGA xsd
xsd_path = "/opt/submission-excel2xml/"
#xsd_path = "xsd/"

xml_a = []
Dir.glob("#{submission_id}*xml").each{|xml|
	meta = xml.match(/#{submission_id}\_(\w+?)\.xml/)[1]
	xml_a.push(meta)
	
	# filepath to xsd
	result = system("xmllint --schema #{xsd_path}JGA.#{meta.downcase}.xsd --noout #{submission_id}_#{meta}.xml")
}

##
## Check relations
##
submission_a = Array.new
study_a = Array.new
sample_a = Array.new

experiment_a = Array.new
experiment_study_ref_a = Array.new
experiment_sample_ref_a = Array.new

data_a = Array.new
data_experiment_ref_a = Array.new

analysis_a = Array.new
analysis_study_ref_a = Array.new
analysis_data_ref_a = Array.new
analysis_sample_ref_a = Array.new

dataset_a = Array.new
dataset_data_ref_a = Array.new
dataset_analysis_ref_a = Array.new
dataset_policy_ref_a = Array.new
dataset_data_ref_per_dataset_a = Array.new
dataset_analysis_ref_per_dataset_a = Array.new
datasets_data_ref_h = Hash.new
datasets_analysis_ref_h = Hash.new

policy_a = Array.new
nbdc_policy = false

center_name_a = Array.new
refcenter_a = Array.new

for meta in xml_a
	case meta.downcase
	when "submission"
		doc = REXML::Document.new(open("#{submission_id}_#{meta}.xml"))
		doc.elements.each("SUBMISSION"){|submission_e|
			submission_a.push(submission_e.attributes["alias"])
			center_name_a.push(submission_e.attributes["center_name"])
		}
	when "study"
		doc = REXML::Document.new(open("#{submission_id}_#{meta}.xml"))
		doc.elements.each("STUDY_SET/STUDY"){|study_e|
			study_a.push(study_e.attributes["alias"])
			center_name_a.push(study_e.attributes["center_name"])
		}
	when "sample"
		doc = REXML::Document.new(open("#{submission_id}_#{meta}.xml"))
		doc.elements.each("SAMPLE_SET/SAMPLE"){|sample_e|
			sample_a.push(sample_e.attributes["alias"])
			center_name_a.push(sample_e.attributes["center_name"])
		}
	
	when "experiment"
		doc = REXML::Document.new(open("#{submission_id}_#{meta}.xml"))
		doc.elements.each("EXPERIMENT_SET/EXPERIMENT"){|experiment_e|
			experiment_a.push(experiment_e.attributes["alias"])
			center_name_a.push(experiment_e.attributes["center_name"])
			
			# study_ref
			experiment_study_ref_a.push(experiment_e.elements["STUDY_REF"].attributes["refname"])
			center_name_a.push(experiment_e.elements["STUDY_REF"].attributes["refcenter"])

			# sample_ref
			experiment_sample_ref_a.push(experiment_e.elements["SAMPLE_REF"].attributes["refname"])
			center_name_a.push(experiment_e.elements["SAMPLE_REF"].attributes["refcenter"])			
		}
		
	when "data"
		doc = REXML::Document.new(open("#{submission_id}_#{meta}.xml"))
		doc.elements.each("DATA_CONTAINER/DATA"){|data_e|
			data_a.push(data_e.attributes["alias"])
			center_name_a.push(data_e.attributes["center_name"])
			
			# experiment_ref
			data_experiment_ref_a.push(data_e.elements["EXPERIMENT_REF"].attributes["refname"])
			center_name_a.push(data_e.elements["EXPERIMENT_REF"].attributes["refcenter"])
		}

	when "analysis"
		doc = REXML::Document.new(open("#{submission_id}_#{meta}.xml"))
		doc.elements.each("ANALYSIS_SET/ANALYSIS"){|analysis_e|
			analysis_a.push(analysis_e.attributes["alias"])
			center_name_a.push(analysis_e.attributes["center_name"])
			
			# study_ref
			analysis_e.elements.each("STUDY_REFS/STUDY_REF"){|study_ref|
				analysis_study_ref_a.push(study_ref.attributes["refname"])
				center_name_a.push(study_ref.attributes["refcenter"])
			}
			
			# sample_ref
			analysis_e.elements.each("SAMPLE_REFS/SAMPLE_REF"){|sample_ref|
				analysis_sample_ref_a.push(sample_ref.attributes["refname"])
				center_name_a.push(sample_ref.attributes["refcenter"])
			}
			
			# data_ref
			analysis_e.elements.each("DATA_REFS/DATA_REF"){|data_ref|
				analysis_data_ref_a.push(data_ref.attributes["refname"])
				center_name_a.push(data_ref.attributes["refcenter"])
			}

		}

	when "dataset"
		doc = REXML::Document.new(open("#{submission_id}_#{meta}.xml"))
		doc.elements.each("DATASETS/DATASET"){|dataset_e|
			
			dataset_alias = dataset_e.attributes["alias"]
			dataset_data_ref_per_dataset_a = Array.new
			dataset_analysis_ref_per_dataset_a = Array.new

			dataset_a.push(dataset_alias)
			center_name_a.push(dataset_e.attributes["center_name"])
		
			# data_ref
			dataset_e.elements.each("DATA_REFS/DATA_REF"){|data_ref|
				dataset_data_ref_a.push(data_ref.attributes["refname"])
				dataset_data_ref_per_dataset_a.push(data_ref.attributes["refname"])
				center_name_a.push(data_ref.attributes["refcenter"])
			}
		
			# analysis_ref
			dataset_e.elements.each("ANALYSIS_REFS/ANALYSIS_REF"){|analysis_ref|
				dataset_analysis_ref_a.push(analysis_ref.attributes["refname"])
				dataset_analysis_ref_per_dataset_a.push(analysis_ref.attributes["refname"])
				center_name_a.push(analysis_ref.attributes["refcenter"])
			}

			# policy_ref
			if dataset_e.elements["POLICY_REF"].attributes["accession"] == "JGAP000001"
				nbdc_policy = true
			else
				dataset_policy_ref_a.push(dataset_e.elements["POLICY_REF"].attributes["accession"])
				center_name_a.push(dataset_e.elements["POLICY_REF"].attributes["refcenter"])
			end

			# more than one Dataset
			datasets_data_ref_h.store(dataset_alias, dataset_data_ref_per_dataset_a.sort.uniq)
			datasets_analysis_ref_h.store(dataset_alias, dataset_analysis_ref_per_dataset_a.sort.uniq)
		
		}
		
	end

end

## Experiment
# Experiment -> Study
if experiment_study_ref_a.sort.uniq != study_a.sort.uniq
	puts "Error: Experiment to Study ref"
end

# Experiment -> Sample
if experiment_sample_ref_a.sort.uniq != sample_a.sort.uniq
	puts "Warning: All samples are not referenced by Experiment"
	puts (experiment_sample_ref_a.sort.uniq - sample_a.sort.uniq)
end

## Data
# Data -> Experiment
if !(data_experiment_ref_a - experiment_a).empty? || !(experiment_a - data_experiment_ref_a).empty?
	puts "Error: Data to Experiment ref"
	puts (data_experiment_ref_a - experiment_a)
end

## Analysis
# Analysis -> Study
unless analysis_study_ref_a.empty?
	if !(analysis_study_ref_a - study_a).empty? || !(study_a - analysis_study_ref_a).empty?
		puts "Error: Analysis to Study  ref"
	end
end

# Analysis -> Data
unless analysis_study_ref_a.empty?
	if !(analysis_data_ref_a - data_a).empty? || !(data_a - analysis_data_ref_a).empty?
		puts "Error: Analysis to Data ref"
	end
end

# Analysis -> Sample
unless analysis_study_ref_a.empty?
	if !(analysis_sample_ref_a - sample_a).empty? || !(sample_a - analysis_sample_ref_a).empty?
		puts "Warning: All samples are not referenced by Analysis"
	end
end

# Experiment, Analysis -> Sample
unless analysis_study_ref_a.empty?
	if !(experiment_sample_ref_a + analysis_sample_ref_a - sample_a).empty? || !(sample_a - analysis_sample_ref_a - experiment_sample_ref_a).empty?
		puts "Warning: All samples are not referenced by Analysis and Experiment"
	end
end

## Data set
# Dataset -> Data
if dataset_data_ref_a.sort.uniq != data_a.sort.uniq
	puts "Error: Dataset to Data ref"
end

# Dataset -> Analysis
if dataset_analysis_ref_a.sort.uniq != analysis_a.sort.uniq
	puts "Error: Dataset to Analysis ref"
end

# Dataset -> Policy
if !nbdc_policy && dataset_policy_ref_a.sort.uniq[0] !~ /JGAP\d{11}/
	puts "Error: Dataset to Policy ref"
end

## if there are more than one Dataset, check duplicated references to Data and Analysis.
# Data
datasets_data_ref_values_a = datasets_data_ref_h.values.flatten
datasets_data_ref_duplicated_a = Array.new
datasets_data_ref_duplicated_a = datasets_data_ref_values_a.select{|e| datasets_data_ref_values_a.count(e) > 1 }.sort.uniq

# Dataset to Analysis references are duplicated.
if datasets_data_ref_duplicated_a.size > 0
	puts "Error: Dataset to Data ref duplicated among Datasets: #{datasets_data_ref_duplicated_a.join(",")}"	
end

# Analysis
datasets_analysis_ref_values_a = datasets_analysis_ref_h.values.flatten
datasets_analysis_ref_duplicated_a = Array.new
datasets_analysis_ref_duplicated_a = datasets_analysis_ref_values_a.select{|e| datasets_analysis_ref_values_a.count(e) > 1 }.sort.uniq

# Dataset to Analysis references are duplicated.
if datasets_analysis_ref_duplicated_a.size > 0
	puts "Error: Dataset to Analysis ref duplicated among Datasets: #{datasets_analysis_ref_duplicated_a.join(",")}"	
end