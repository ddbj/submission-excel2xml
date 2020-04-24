# Excel and container images for DRA metadata XML submission  

* Bioinformation and DDBJ Center
* release: 2020-04-24  
* version: v1.1

These files are Excel, Singularity and Docker container images and SRA xsd for generation and validation of Submission, Experiment and Run XMLs for [DDBJ Sequence Read Archive (DRA)](https://www.ddbj.nig.ac.jp/dra/submission-e.html) submission. 

## Download

Download the DDBJ public repository.  
```
git clone https://github.com/ddbj/submission-excel2xml.git
```

## Enter metadata in the excel

Enter metadata and data files in the 'Submission', 'Experiment', 'Run' and 'Run-file' sheets of the excel.  
See our [website](https://www.ddbj.nig.ac.jp/dra/submission-e.html#metadata) for metadata and 'Readme' sheet of the excel for details.   
See 'example-0001_dra_metadata.xlsx' for example.

### Generate XMLs: Singularity  

Build the Singularity image.
```
cd submission-excel2xml
sudo singularity build excel2xml.simg Singularity
```

Generate Submission, Experiment and Run XMLs from the excel.    
Specify the D-way account ID, submission number and BioProject accession.  

For example,  
* DRA submission id 'example-0001': -a example -i 0001  
* BioProject 'PRJDB7252' : -p PRJDB7252  
```
singularity exec excel2xml.simg excel2xml.rb -a example -i 0001 -p PRJDB7252 example-0001_dra_metadata.xlsx
```

Three XMLs are generated from the excel.
* example-0001_Submission.xml
* example-0001_Experiment.xml
* example-0001_Run.xml

Validate the XMLs by specifying the submission ID.
```
singularity exec excel2xml.simg validate_dra_meta.rb -a example -i 0001
```

Please note that this validator only performs xsd validation and minimum checks.   
The XMLs are fully validated in the DRA web XML registration process, 
so the checked XMLs may be failed in the DRA submission system. 

### Generate XMLs: Docker  

Build the Docker image.
```
cd submission-excel2xml
sudo docker build -t excel2xml .
```

Generate Submission, Experiment and Run XMLs from the excel.    
Specify the D-way account ID, submission number, BioProject accession and full path of the directory which contains the excel.  

For example,  
* DRA submission id 'example-0001': -a example -i 0001  
* BioProject 'PRJDB7252' : -p PRJDB7252  
* 'path_to_excel_directory': full path of the directory which contains the excel.  
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml excel2xml.rb -a example -i 0001 -p PRJDB7252 example-0001_dra_metadata.xlsx
```

Three XMLs are generated from the excel.  
* example-0001_Submission.xml
* example-0001_Experiment.xml
* example-0001_Run.xml

Validate the XMLs by specifying the submission ID.
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml validate_dra_meta.rb -a example -i 0001
```

Please note that this validator only performs xsd validation and minimum checks.   
The XMLs are fully validated in the DRA web XML registration process, 
so the checked XMLs may be failed in the DRA submission system. 

## Validation results  

### XML validation against SRA xsd 

* Metadata XMLs are validated against [respective SRA xsd](https://github.com/ddbj/pub/tree/master/docs/dra/xsd/1-5). Modify the XMLs according to the xsd validation messages.  

### XML content check

**Submission** 
* Error: Submission: Past hold date.  
Set the future hold date.  

**Experiment and Run** 
* Error: Run: #{run_alias} Paired library only has one file.  
Include at least two sequence data files (for example, R1.fastq and R2.fastq) for paired library Experiment.  

### Object reference check 
* Error: Run to Experiment reference error.  
Not all Experiments are referenced by Runs.  
There is Run(s) not referencing Experiment.  
There is Experiment(s) not referenced by Run.  
Modify metadata to make all Runs reference all Experiments.  

See [the DRA Handbook](https://www.ddbj.nig.ac.jp/dra/submission-e.html#metadata-objects) for metadata model.  

## Submit XMLs in the DRA web interface  

Before submitting the metadata XMLs, [upload sequence data files to the submission directory](https://www.ddbj.nig.ac.jp/dra/submission-e.html#upload-sequence-data).  
After logging in the D-way, [upload the Submission, Experiment and Run XMLs in the XML upload area of the DRA submission](https://www.ddbj.nig.ac.jp/dra/submission-e.html#create-metadata-in-xml-files).  

