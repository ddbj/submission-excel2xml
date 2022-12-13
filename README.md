# Excel and container images for DRA metadata XML submission  

## 日本語  

* 生命情報・DDBJ センター
* 公開日: 2022-12-13
* version: v1.4

[DDBJ Sequence Read Archive (DRA)](https://www.ddbj.nig.ac.jp/dra/submission.html) に登録するための Submission、Experiment と Run XML を生成・チェックするためのエクセル、Singularity と Docker コンテナ、及び、SRA xsd。

## 履歴

* 2022-12-13: v1.4 リード長とペアリードの向きの記入の不要化に対応
* 2021-12-13: v1.3 BGISEQ 追加
* 2021-07-13: v1.2 [xsd 1.5.9](https://github.com/ddbj/pub/tree/master/docs/dra#changes-to-common-xml-159-on-7-july-2021) に対応。xsd を [pub](https://github.com/ddbj/pub) から取得するように変更。
* 2020-04-24: v1.1 初版

## ダウンロード

submission-excel2xml レポジトリをダウンロードします。  
```
git clone https://github.com/ddbj/submission-excel2xml.git
```

## エクセルにメタデータを記入  

メタデータとデータファイルをエクセルの 'Submission'、'Experiment'、'Run' と 'Run-file' シートに記入します。メタデータについては[ウェブサイト](https://www.ddbj.nig.ac.jp/dra/submission.html#metadata)と 'Readme' シートをご覧ください。  
'example-0001_dra_metadata.xlsx' が記入例になります。  

### XML を生成: Singularity  

Singularity イメージを[ダウンロード](https://drive.google.com/drive/u/3/folders/1Qrqpgjw_No5q6mO6rcihNwVCyMBVytzL)、もしくは、以下の手順でローカル環境で構築します。  
```
cd submission-excel2xml
sudo singularity build excel2xml.simg Singularity
```

エクセルから Submission、Experiment と Run XML を生成します。
D-way アカウント ID、submission 番号と BioProject アクセッション番号を指定します。

例
* DRA submission id 'example-0001': -a example -i 0001  
* BioProject 'PRJDB7252' : -p PRJDB7252  
```
singularity exec excel2xml.simg excel2xml.rb -a example -i 0001 -p PRJDB7252 example-0001_dra_metadata.xlsx
```

エクセルから三つの XML が生成されます。  
* example-0001_Submission.xml
* example-0001_Experiment.xml
* example-0001_Run.xml

Submission ID を指定して XML をチェックします。XML は submission-excel2xml ディレクトリ直下に配置されている必要があります。SRA xsd ファイルは build 中にコンテナー内の /opt/submission-excel2xml/ にダウンロードされています。          
```
singularity exec excel2xml.simg validate_dra_meta.rb -a example -i 0001
```

ここでは xsd に対するチェックと最低限のチェックが実施されます。  
DRA の登録サイトではより詳細なチェックが実施されるため、パスした XML が登録過程でエラーになることがあります。  

### XML を生成: Docker  

Docker イメージを構築します。  
```
cd submission-excel2xml
sudo docker build -t excel2xml .
```

エクセルから Submission、Experiment と Run XML を生成します。  
D-way アカウント ID、submission 番号、BioProject アクセッション番号とエクセルを含むディレクトリのフルパスを指定します。  

例
* DRA submission id 'example-0001': -a example -i 0001  
* BioProject 'PRJDB7252' : -p PRJDB7252  
* 'path_to_excel_directory': エクセルを含むディレクトリのフルパス  
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml excel2xml.rb -a example -i 0001 -p PRJDB7252 example-0001_dra_metadata.xlsx
```

エクセルから三つの XML が生成されます。 
* example-0001_Submission.xml
* example-0001_Experiment.xml
* example-0001_Run.xml

Submission ID を指定して XML をチェックします。XML は submission-excel2xml ディレクトリ直下に配置されている必要があります。SRA xsd ファイルは build 中にコンテナー内の /opt/submission-excel2xml/ にダウンロードされています。        
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml validate_dra_meta.rb -a example -i 0001
```

ここでは xsd に対するチェックと最低限のチェックが実施されます。  
DRA の登録サイトではより詳細なチェックが実施されるため、パスした XML が登録過程でエラーになることがあります。  

## チェック結果    

### SRA xsd に対する XML チェック  

* メタデータ XML は [SRA xsd](https://github.com/ddbj/pub/tree/master/docs/dra/xsd/1-5) に対してチェックされます。メッセージに従って XML を修正してください。  

### XML の内容チェック  

**Submission** 
* Error: Submission: 公開予定日が過去の日付   
将来の日付を指定してください。  

**Experiment と Run** 
* Error: Run: #{run_alias} Paired library only has one file.  
ペアライブラリ Experiment では少なくとも二つの配列データファイル (例、R1.fastq と R2.fastq) が含まれている必要があります。  

### オブジェクトの参照関係チェック
* Error: Run to Experiment reference error.  
全ての Experiment が Run から参照されていない。  
Experiment を参照していない Run が存在する。  
Run から参照されていない Experiment が存在する。
このような場合、全ての Run が全ての Experiment を参照するように修正してください。  

メタデータモデルは [DRA Handbook](https://www.ddbj.nig.ac.jp/dra/submission.html#metadata-objects) を参照してください。  

## DRA ウェブ画面から XML を登録する  

メタデータ XML を登録する前に[登録ディレクトリに配列データファイルをアップロードします](https://www.ddbj.nig.ac.jp/dra/submission.html#upload-sequence-data)。D-way にログイン後、[Submission、Experiment と Run XML を DRA 登録ページででアップロード](https://www.ddbj.nig.ac.jp/dra/submission.html#create-metadata-in-xml-files) します。   
ブラウザーがタイムアウトしても処理は続いておりますので、ブラウザーを閉じてしばらく放置しておくと登録が完了します。

## Github や XML 生成方法が分からない場合  

[DRA メタデータエクセル](https://www.ddbj.nig.ac.jp/files/submission/dra_metadata.xlsx) をウェブサイトからダウンロード、内容を英語で記入し、メール (trace@ddbj.nig.ac.jp) 添付で DRA チームにお送りください。   

## NIG スパコンでの実施方法

国立遺伝学研究所 生命情報・DDBJ センターが運営する [NIG スパコン](https://www.ddbj.nig.ac.jp/sc) では `/lustre6/public/app/submission-excel2xml/` 
に Singularity イメージが設置されています。ダウンロードや build 作業をすることなく、メタデータエクセルファイルがあれば XML 生成や XML のチェックを実施することができます。    
多件数のデータファイルがスパコンにある場合、メタデータ XML 作成、及び、データファイルの DRA ファイル受付サーバ (ftp-private.ddbj.nig.ac.jp) への転送をスパコン上で完結することができます。

エクセルから Submission、Experiment と Run XML を生成。
```
singularity exec /lustre6/public/app/submission-excel2xml/excel2xml.simg excel2xml.rb -a example -i 0001 -p PRJDB7252 example-0001_dra_metadata.xlsx
```

XML のチェック。
```
singularity exec /lustre6/public/app/submission-excel2xml/excel2xml.simg validate_dra_meta.rb -a example -i 0001
```

## English  

* Bioinformation and DDBJ Center
* release: 2022-12-13    
* version: v1.4

These files are Excel, Singularity and Docker container images and SRA xsd for generation and validation of Submission, Experiment and Run XMLs for [DDBJ Sequence Read Archive (DRA)](https://www.ddbj.nig.ac.jp/dra/submission-e.html) submission. 

## History

* 2022-12-13: v1.4 Read length and direction of paired reads were made optional  
* 2021-12-13: v1.3 BGISEQ added  
* 2021-07-13: v1.2 Update to [xsd 1.5.9](https://github.com/ddbj/pub/tree/master/docs/dra#changes-to-common-xml-159-on-7-july-2021). Download the xsd files from [pub](https://github.com/ddbj/pub).
* 2020-04-24: v1.1 Initial release

## Download

Download the DDBJ submission-excel2xml repository.  
```
git clone https://github.com/ddbj/submission-excel2xml.git
```

## Enter metadata in the excel

Enter metadata and data files in the 'Submission', 'Experiment', 'Run' and 'Run-file' sheets of the excel.  
See our [website](https://www.ddbj.nig.ac.jp/dra/submission-e.html#metadata) for metadata and 'Readme' sheet of the excel for details.   
See 'example-0001_dra_metadata.xlsx' for example.

### Generate XMLs: Singularity  

[Download](https://drive.google.com/drive/u/3/folders/1Qrqpgjw_No5q6mO6rcihNwVCyMBVytzL) the Singularity image or build the Singularity image as follows.  
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

Validate the XMLs by specifying the submission ID. The XML files must be under the submission-excel2xml directory. The SRA xsd files have been downloaded to /opt/submission-excel2xml/ from [pub](https://github.com/ddbj/pub) in the container during the build. 
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

Validate the XMLs by specifying the submission ID. The XML files must be under the submission-excel2xml directory. The SRA xsd files have been downloaded to /opt/submission-excel2xml/ from [pub](https://github.com/ddbj/pub) in the container during the build.  
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
Your web browser may time out, however, submission processes are ongoing on the backend. Please close the browser and leave it for a while. The XML submission will be registered.

## When Github and XML generation are not clear for you  

Download [DRA metadata Excel](https://www.ddbj.nig.ac.jp/files/submission/dra_metadata.xlsx) from website, fill in and send it to the DRA team by Email (trace@ddbj.nig.ac.jp).  

## NIG SuperComputer

The singularity image is available at `/lustre6/public/app/submission-excel2xml/` in the [NIG SuperComputer](https://www.ddbj.nig.ac.jp/sc) operated by Bioinformation and DDBJ Center, National Institute of Genetics. The SuperComputer user can readily generate XMLs from the metadata excel file and check the XMLs.    
The user can create DRA metadata XMLs and transfer corresponding data files to the DRA file server (ftp-private.ddbj.nig.ac.jp) in the SuperComputer.

Generate Submission, Experiment and Run XMLs from the excel.
```
singularity exec /lustre6/public/app/submission-excel2xml/excel2xml.simg excel2xml.rb -a example -i 0001 -p PRJDB7252 example-0001_dra_metadata.xlsx
```

Validate the XMLs.
```
singularity exec /lustre6/public/app/submission-excel2xml/excel2xml.simg validate_dra_meta.rb -a example -i 0001
```

