# Excel and container images for DRA/JGA/AGD metadata XML submissions

## 日本語

* 生命情報・DDBJ センター
* 公開日: 2024-10-23
* version: v3.1

[Bioinformation and DDBJ Center](https://www.ddbj.nig.ac.jp/index-e.html) のデータベースに登録するためのメタデータ XML を生成、チェックするツール。
* [DDBJ Sequence Read Archive (DRA)](https://www.ddbj.nig.ac.jp/dra/submission.html): Submission、Experiment、Run と Analysis (任意) XML を生成・チェックするためのエクセルとスクリプト
* [Japanese Genotype-phenotype Archive (JGA)](https://www.ddbj.nig.ac.jp/jga/submission.html): Submission、Study、Sample、Experiment、Data、Analysis と Dataset XML を生成・チェックするためのエクセルとスクリプト
* [AMED Genome Group Sharing Database (AGD)](https://www.ddbj.nig.ac.jp/agd/submission.html): Submission、Study、Sample、Experiment、Data、Analysis と Dataset XML を生成・チェックするためのエクセルとスクリプト

## 履歴

* 2024-10-23: v3.1 Library Source SINGLE CELL
* 2024-07-05: v3.0 シート名に DB prefix を付加
* 2024-07-04: v2.9.1 Sample 属性を全て ATTRIBUTE に格納
* 2024-06-14: v2.9 Sample 属性追加、及び、公開指定の削除
* 2024-05-28: v2.8.1 file bug fix
* 2024-05-23: v2.8 md5 桁数エラー追加
* 2024-05-17: v2.7 JGA Sample 追加属性の記載方法を変更
* 2024-02-14: v2.6 DRA xsd 1.6.0
* 2024-01-31: v2.5 テンプレート・サンプルデータの修正
* 2023-12-21: v2.4 center name 変更
* 2023-12-05: v2.3 Analysis step と Attributes 複数値の区切りを , から ; に変更
* 2023-12-01: v2.2 gem 化
* 2023-11-21: v2.1 Analysis に Run カラム追加
* 2023-09-04: v2.0 Analysis 対応
* 2023-02-09: v1.9.2 Run title
* 2023-01-17: v1.9.1 PAIRED で NOMINAL_LENGTH を任意化
* 2022-12-23: v1.9 JGA メタデータエクセルに AGD を統合
* 2022-12-22: v1.8 AGD 対応
* 2022-12-21: v1.7 JGA Dataset reference 重複チェックを追加
* 2022-12-15: v1.6 JGA を追加
* 2022-12-14: v1.5 DRA を明確化
* 2022-12-13: v1.4 リード長とペアリードの向きの記入の不要化に対応
* 2021-12-13: v1.3 BGISEQ 追加
* 2021-07-13: v1.2 [xsd 1.5.9](https://github.com/ddbj/pub/tree/master/docs/dra#changes-to-common-xml-159-on-7-july-2021) に対応。xsd を [pub](https://github.com/ddbj/pub) から取得するように変更。
* 2020-04-24: v1.1 初版

## ダウンロード

submission-excel2xml レポジトリをダウンロードします。
```
git clone https://github.com/ddbj/submission-excel2xml.git
```

## イメージ構築

### Singularity

Singularity イメージを[ダウンロード](https://ddbj.nig.ac.jp/public/software/submission-excel2xml/)、もしくは、以下の手順でローカル環境で構築します。
```
cd submission-excel2xml
sudo singularity build excel2xml.simg Singularity
```

### Docker

Docker イメージを以下の手順でローカル環境で構築します。
```
cd submission-excel2xml
sudo docker build -t excel2xml .
```

## DRA

### エクセルにメタデータを記入

メタデータとデータファイルをエクセル metadata_dra.xlsx の 'Submission'、'Experiment'、'Run' と 'Run-file' シートに記入します。メタデータについては[ウェブサイト](https://www.ddbj.nig.ac.jp/dra/submission.html#metadata)と 'Readme' シートをご覧ください。
'example/example-0001_dra_metadata.xlsx' が記入例になります。

Analysis (任意) を登録する場合は 'Analysis' シートに記入します。Analysis のみを新規登録することはできず、Run を持った Submission に登録します。
'example/example-0002_dra_metadata.xlsx' が記入例になります。

### XML 生成とチェック: Singularity

エクセルから Submission、Experiment と Run XML を生成します。
D-way アカウント ID、submission 番号と BioProject アクセッション番号を指定します。

例
* DRA submission id 'example-0001': -a example -i 0001
* BioProject 'PRJDB7252' : -p PRJDB7252
```
singularity exec excel2xml.simg excel2xml_dra -a example -i 0001 -p PRJDB7252 example/example-0001_dra_metadata.xlsx
```

エクセルから三つの XML が生成されます。
* example-0001_dra_Submission.xml
* example-0001_dra_Experiment.xml
* example-0001_dra_Run.xml

Analysis シートが記入されている場合は Analysis XML も生成されます。
* example-0001_dra_Analysis.xml

Submission ID を指定して XML をチェックします。XML は submission-excel2xml ディレクトリ直下に配置されている必要があります。SRA xsd ファイルは build 中にコンテナー内の /opt/submission-excel2xml/ にダウンロードされています。
```
singularity exec excel2xml.simg validate_meta_dra -a example -i 0001
```

ここでは xsd に対するチェックと最低限のチェックが実施されます。
DRA の登録サイトではより詳細なチェックが実施されるため、パスした XML が登録過程でエラーになることがあります。

#### Analysis XML のみを生成

既存 Submission に Analysis を追加する場合、'Analysis' シートのみを記入し、Analysis XML を生成します。XML 生成時に -c で center name を指定します。

例
* DRA submission id 'example-0002': -a example -i 0002
* BioProject 'PRJDB7252' : -p PRJDB7252
* Center name: National Institute of Genetics
```
singularity exec excel2xml.simg excel2xml_dra -a example -i 0002 -p PRJDB7252 -c "National Institute of Genetics" example/example-0002_dra_metadata.xlsx
```

エクセルから Analysis XML が生成されます。
* example-0002_dra_Analysis.xml

### XML 生成とチェック: Docker

エクセルから Submission、Experiment と Run XML を生成します。
D-way アカウント ID、submission 番号、BioProject アクセッション番号とエクセルを含むディレクトリのフルパスを指定します。

例
* DRA submission id 'example-0001': -a example -i 0001
* BioProject 'PRJDB7252' : -p PRJDB7252
* 'path_to_excel_directory': エクセルを含むディレクトリのフルパス
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml excel2xml_dra -a example -i 0001 -p PRJDB7252 example/example-0001_dra_metadata.xlsx
```

エクセルから三つの XML が生成されます。
* example-0001_dra_Submission.xml
* example-0001_dra_Experiment.xml
* example-0001_dra_Run.xml

Analysis シートが記入されている場合は Analysis XML も生成されます。
* example-0001_dra_Analysis.xml

Submission ID を指定して XML をチェックします。XML は submission-excel2xml ディレクトリ直下に配置されている必要があります。SRA xsd ファイルは build 中にコンテナー内の /opt/submission-excel2xml/ にダウンロードされています。
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml validate_meta_dra -a example -i 0001
```

ここでは xsd に対するチェックと最低限のチェックが実施されます。
DRA の登録サイトではより詳細なチェックが実施されるため、パスした XML が登録過程でエラーになることがあります。

#### Analysis XML のみを生成

既存 Submission に Analysis を追加する場合、'Analysis' シートのみを記入し、Analysis XML を生成します。XML 生成時に -c で center name を指定します。

例
* DRA submission id 'example-0002': -a example -i 0002
* BioProject 'PRJDB7252' : -p PRJDB7252
* Center name: National Institute of Genetics
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml excel2xml_dra -a example -i 0002 -p PRJDB7252 -c "National Institute of Genetics" example/example-0002_dra_metadata.xlsx
```

エクセルから Analysis XML が生成されます。
* example-0002_dra_Analysis.xml

### チェック

#### SRA xsd に対する XML チェック

* メタデータ XML は [SRA xsd](https://github.com/ddbj/pub/tree/master/docs/dra/xsd/1-5) に対してチェックされます。メッセージに従って XML を修正してください。

#### XML の内容チェック

**Submission**
* Error: Submission: 公開予定日が過去の日付
将来の日付を指定してください。

**Experiment と Run**
* Error: Run: #{run_alias} Paired library only has one file.
ペアライブラリ Experiment では少なくとも二つの配列データファイル (例、R1.fastq と R2.fastq) が含まれている必要があります。

#### オブジェクトの参照関係チェック
* Error: Run to Experiment reference error.
全ての Experiment が Run から参照されていない。
Experiment を参照していない Run が存在する。
Run から参照されていない Experiment が存在する。
このような場合、全ての Run が全ての Experiment を参照するように修正してください。

メタデータモデルは [DRA Handbook](https://www.ddbj.nig.ac.jp/dra/submission.html#metadata-objects) を参照してください。

### DRA ウェブ画面から XML を登録する

メタデータ XML を登録する前に[登録ディレクトリに配列データファイルをアップロードします](https://www.ddbj.nig.ac.jp/dra/submission.html#upload-sequence-data)。D-way にログイン後、[Submission、Experiment と Run XML を DRA 登録ページででアップロード](https://www.ddbj.nig.ac.jp/dra/submission.html#create-metadata-in-xml-files) します。通常5分以内に登録が完了します。

### Github や XML 生成方法が分からない場合

[DRA メタデータエクセル](https://github.com/ddbj/submission-excel2xml/blob/main/metadata_dra.xlsx) をダウンロード、内容を英語で記入し、メール (trace@ddbj.nig.ac.jp) 添付で DRA チームにお送りください。

## JGA

### エクセルにメタデータを記入

メタデータとデータファイルをエクセル JGA_metadata.xlsx の 'Submission'、'Study'、'Sample'、'Experiment'、'Data'、'Analysis' (該当する場合)、'Dataset' と 'File' シートに記入します。
メタデータについては[ウェブサイト](https://www.ddbj.nig.ac.jp/jga/submission.html)と 'Readme' シートをご覧ください。
'example/JSUB999999_jga_metadata.xlsx' が記入例になります。

### XML 生成とチェック: Singularity

エクセルから Submission、Study、Sample、Experiment、Data、Analysis (該当する場合)、Dataset XML を生成します。
JGA submission id を指定します。

例
* JGA Submission ID 'JSUB999999': -j JSUB999999
```
singularity exec excel2xml.simg excel2xml_jga -j JSUB999999 example/JSUB999999_jga_metadata.xlsx
```

エクセルから七つの XML が生成されます。
* JSUB999999_Analysis.xml
* JSUB999999_Data.xml
* JSUB999999_Dataset.xml
* JSUB999999_Experiment.xml
* JSUB999999_Sample.xml
* JSUB999999_Study.xml
* JSUB999999_Submission.xml

Sample 追加属性の記載方法が v2.6 以前の形式 (例 age:37; collection_date:2015-03-05) の場合、-r オプションを付けて XML を生成します。　　

JGA Submission ID を指定して XML をチェックします。XML は submission-excel2xml ディレクトリ直下に配置されている必要があります。JGA xsd ファイルは build 中にコンテナー内の /opt/submission-excel2xml/ にダウンロードされています。
```
singularity exec excel2xml.simg validate_meta_jga -j JSUB999999
```

ここでは xsd に対するチェックと最低限のチェックが実施されます。

### XML 生成とチェック: Docker

エクセルから Submission、Study、Sample、Experiment、Data、Analysis (該当する場合)、Dataset XML を生成します。
JGA submission id を指定します。

例
* JGA Submission ID 'JSUB999999': -j JSUB999999
* 'path_to_excel_directory': エクセルを含むディレクトリのフルパス
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml excel2xml_jga -j JSUB999999 example/JSUB999999_jga_metadata.xlsx
```

エクセルから七つの XML が生成されます。
* JSUB999999_Analysis.xml
* JSUB999999_Data.xml
* JSUB999999_Dataset.xml
* JSUB999999_Experiment.xml
* JSUB999999_Sample.xml
* JSUB999999_Study.xml
* JSUB999999_Submission.xml

Sample 追加属性の記載方法が v2.6 以前の形式 (例 age:37; collection_date:2015-03-05) の場合、-r オプションを付けて XML を生成します。　　

Submission ID を指定して XML をチェックします。XML は submission-excel2xml ディレクトリ直下に配置されている必要があります。JGA xsd ファイルは build 中にコンテナー内の /opt/submission-excel2xml/ にダウンロードされています。
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml validate_meta_jga -j JSUB999999
```

ここでは xsd に対するチェックと最低限のチェックが実施されます。

### チェック

#### JGA xsd に対する XML チェック

* メタデータ XML は [JGA xsd](https://github.com/ddbj/pub/tree/master/docs/jga/xsd/1-2) に対してチェックされます。メッセージに従って XML を修正してください。

#### XML の内容チェック

#### オブジェクトの参照関係チェック

以下のオブジェクト間の関係がチェックされます。

* Data -> Experiment
* Analysis -> Study
* Analysis -> Data
* Analysis -> Sample
* Experiment -> Sample
* Analysis -> Sample
* Dataset -> Data
* Dataset -> Analysis
* Dataset -> Policy

### XML を登録する

XML を JGA データ受付サーバにアップロードします。アップロードする前に [NBDC 事業推進部](https://humandbs.biosciencedbc.jp/en/data-submission) で提供申請が承認されている必要があります。

### Github や XML 生成方法が分からない場合

[JGA メタデータエクセル](https://github.com/ddbj/submission-excel2xml/raw/main/JGA_metadata.xlsx)をダウンロード、内容を英語で記入し、メール (jga@ddbj.nig.ac.jp) 添付で JGA チームにお送りください。

## AGD

JGA と同様の手順になります。AGD のメタデータも JGA_metadata.xlsx に記入します。
Submission ID には AGD Submission ID (例 ASUB000001) を指定します。

## NIG スパコンでの実施方法

国立遺伝学研究所 生命情報・DDBJ センターが運営する [NIG スパコン](https://www.ddbj.nig.ac.jp/sc) では `/lustre9/open/shared_data/software/submission-excel2xml/`
に Singularity イメージが設置されています。ダウンロードや build 作業をすることなく、メタデータエクセルファイルがあれば XML 生成や XML のチェックを実施することができます。

### DRA

多件数のデータファイルがスパコンにある場合、メタデータ XML 作成、及び、データファイルの DRA ファイル受付サーバ (ftp-private.ddbj.nig.ac.jp) への転送をスパコン上で完結することができます。

エクセルから Submission、Experiment と Run XML を生成。
```
cp /lustre9/open/shared_data/software/submission-excel2xml/excel2xml.simg ~/
cd
singularity exec excel2xml.simg excel2xml_dra -a example -i 0001 -p PRJDB7252 example/example-0001_dra_metadata.xlsx
```

XML のチェック。
```
singularity exec excel2xml.simg validate_meta_dra -a example -i 0001
```

### JGA

TBD

### AGD

TBD

## English

* Bioinformation and DDBJ Center
* release: 2024-10-23
* version: v3.1

These files are Excel, container images and tools for generation and validation of metadata XML files for databases of [Bioinformation and DDBJ Center](https://www.ddbj.nig.ac.jp/index-e.html).
* [DDBJ Sequence Read Archive (DRA)](https://www.ddbj.nig.ac.jp/dra/submission-e.html): generate and check Submission, Experiment and Run XML files.
* [Japanese Genotype-phenotype Archive (JGA)](https://www.ddbj.nig.ac.jp/jga/submission-e.html): generate and check Submission, Study, Sample, Experiment, Data, Analysis and Dataset XML files.
* [AMED Genome Group Sharing Database (AGD)](https://www.ddbj.nig.ac.jp/agd/submission-e.html): generate and check Submission, Study, Sample, Experiment, Data, Analysis and Dataset XML files.

## History

* 2024-10-23: v3.1 Library Source SINGLE CELL
* 2024-07-05: v3.0 DB prefix added to sheet name
* 2024-07-04: v2.9.1 Store all sample attributes in SAMPLE_ATTRIBUTE
* 2024-06-14: v2.9 Sample attributes added and hold/release removed
* 2024-05-28: v2.8.1 file bug fix
* 2024-05-23: v2.8 md5 checksum value digit check added
* 2024-05-17: v2.7 Added sample attributes description format changed
* 2024-02-14: v2.6 DRA xsd 1.6.0
* 2024-01-31: v2.5 Fixing templates and sample data
* 2023-12-21: v2.4 center name changes
* 2023-12-05: v2.3 Delimiter of Analysis step and Attributes was changed from "," to ";"
* 2023-12-01: v2.2 gem
* 2023-11-21: v2.1 Run column added to Analysis
* 2023-02-09: v2.0 Analysis support
* 2023-02-09: v1.9.2 Run Title
* 2023-01-17: v1.9.1 NOMINAL_LENGTH was made optional for PAIRED
* 2022-12-23: v1.9 AGD merged to the JGA excel
* 2022-12-22: v1.8 AGD
* 2022-12-21: v1.7 Dataset reference duplication check added
* 2022-12-15: v1.6 JGA added
* 2022-12-14: v1.5 DRA separated
* 2022-12-13: v1.4 Read length and direction of paired reads were made optional
* 2021-12-13: v1.3 BGISEQ added
* 2021-07-13: v1.2 Update to [xsd 1.5.9](https://github.com/ddbj/pub/tree/master/docs/dra#changes-to-common-xml-159-on-7-july-2021). Download the xsd files from [pub](https://github.com/ddbj/pub).
* 2020-04-24: v1.1 Initial release

## Download

Download the DDBJ submission-excel2xml repository.
```
git clone https://github.com/ddbj/submission-excel2xml.git
```

## Image construction

### Singularity

[Download](https://ddbj.nig.ac.jp/public/software/submission-excel2xml/) the Singularity image or build the Singularity image as follows.
```
cd submission-excel2xml
sudo singularity build excel2xml.simg Singularity
```

### Docker

Build the Docker image as follows.
```
cd submission-excel2xml
sudo docker build -t excel2xml .
```

## DRA

### Enter metadata in the excel

Enter metadata and data files in the 'Submission', 'Experiment', 'Run' and 'Run-file' sheets of the excel "metadata_dra.xlsx".
See our [website](https://www.ddbj.nig.ac.jp/dra/submission-e.html#metadata) for metadata and 'Readme' sheet of the excel for details.
See 'example-0001_dra_metadata.xlsx' for example.

To submit Analysis (optional) object(s), enter an 'Analysis' sheet. Analysis-only submission is not acceptable. Submit Analysis to a Submission having Run(s).
See 'example/example-0002_dra_metadata.xlsx' for example.

### Generate XMLs: Singularity

Generate Submission, Experiment and Run XMLs from the excel.
Specify the D-way account ID, submission number and BioProject accession.

For example,
* DRA submission id 'example-0001': -a example -i 0001
* BioProject 'PRJDB7252' : -p PRJDB7252
```
singularity exec excel2xml.simg excel2xml_dra -a example -i 0001 -p PRJDB7252 example/example-0001_dra_metadata.xlsx
```

Three XMLs are generated from the excel.
* example-0001_dra_Submission.xml
* example-0001_dra_Experiment.xml
* example-0001_dra_Run.xml

When an Analysis sheet is filled, an Analysis XML is generated.
* example-0001_dra_Analysis.xml

Validate the XMLs by specifying the submission ID. The XML files must be under the submission-excel2xml directory. The SRA xsd files have been downloaded to /opt/submission-excel2xml/ from [pub](https://github.com/ddbj/pub) in the container during the build.
```
singularity exec excel2xml.simg validate_meta_dra -a example -i 0001
```

Please note that this validator only performs xsd validation and minimum checks.
The XMLs are fully validated in the DRA web XML registration process,
so the checked XMLs may be failed in the DRA submission system.

#### Generate Analysis XML only

To add Analysis object(s) to an existing Submission, you may enter an 'Analysis' sheet only and generate only an Analysis XML. Specify a center name by -c option.

Example
* DRA submission id 'example-0002': -a example -i 0002
* BioProject 'PRJDB7252' : -p PRJDB7252
* Center name: National Institute of Genetics
```
singularity exec excel2xml.simg excel2xml_dra -a example -i 0002 -p PRJDB7252 -c "National Institute of Genetics" example/example-0002_dra_metadata.xlsx
```

An Analysis XML is generated from the excel.
* example-0001_dra_Analysis.xml

### Generate XMLs: Docker

Generate Submission, Experiment and Run XMLs from the excel.
Specify the D-way account ID, submission number, BioProject accession and full path of the directory which contains the excel.

For example,
* DRA submission id 'example-0001': -a example -i 0001
* BioProject 'PRJDB7252' : -p PRJDB7252
* 'path_to_excel_directory': full path of the directory which contains the excel.
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml excel2xml_dra -a example -i 0001 -p PRJDB7252 example/example-0001_dra_metadata.xlsx
```

Three XMLs are generated from the excel.
* example-0001_dra_Submission.xml
* example-0001_dra_Experiment.xml
* example-0001_dra_Run.xml

When an Analysis sheet is filled, an Analysis XML is generated.
* example-0001_dra_Analysis.xml

Validate the XMLs by specifying the submission ID. The XML files must be under the submission-excel2xml directory. The SRA xsd files have been downloaded to /opt/submission-excel2xml/ from [pub](https://github.com/ddbj/pub) in the container during the build.
```
sudo docker run -v /path_to_excel_directory:/data -w /data excel2xml validate_meta_dra -a example -i 0001
```

Please note that this validator only performs xsd validation and minimum checks.
The XMLs are fully validated in the DRA web XML registration process,
so the checked XMLs may be failed in the DRA submission system.

#### Generate Analysis XML only

To add Analysis object(s) to an existing Submission, you may enter an 'Analysis' sheet only and generate only an Analysis XML. Specify a center name by -c option.

Example
* DRA submission id 'example-0002': -a example -i 0002
* BioProject 'PRJDB7252' : -p PRJDB7252
* Center name: National Institute of Genetics
```
singularity exec excel2xml.simg excel2xml_dra -a example -i 0002 -p PRJDB7252 -c "National Institute of Genetics" example/example-0002_dra_metadata.xlsx
```

An Analysis XML is generated from the excel.
* example-0002_dra_Analysis.xml

### Validation results

#### XML validation against SRA xsd

* Metadata XMLs are validated against [respective SRA xsd](https://github.com/ddbj/pub/tree/master/docs/dra/xsd/1-5). Modify the XMLs according to the xsd validation messages.

#### XML content check

**Submission**
* Error: Submission: Past hold date.
Set the future hold date.

**Experiment and Run**
* Error: Run: #{run_alias} Paired library only has one file.
Include at least two sequence data files (for example, R1.fastq and R2.fastq) for paired library Experiment.

#### Object reference check
* Error: Run to Experiment reference error.
Not all Experiments are referenced by Runs.
There is Run(s) not referencing Experiment.
There is Experiment(s) not referenced by Run.
Modify metadata to make all Runs reference all Experiments.

See [the DRA Handbook](https://www.ddbj.nig.ac.jp/dra/submission-e.html#metadata-objects) for metadata model.

### Submit XMLs in the DRA web interface

Before submitting the metadata XMLs, [upload sequence data files to the submission directory](https://www.ddbj.nig.ac.jp/dra/submission-e.html#upload-sequence-data).
After logging in the D-way, [upload the Submission, Experiment and Run XMLs in the XML upload area of the DRA submission](https://www.ddbj.nig.ac.jp/dra/submission-e.html#create-metadata-in-xml-files).
Your web browser may time out, however, submission processes are ongoing on the backend. Please close the browser and leave it for a while. The XML submission will be registered.

### When Github and XML generation are not clear for you

Download [DRA metadata Excel](https://github.com/ddbj/submission-excel2xml/blob/main/metadata_dra.xlsx), fill in and send it to the DRA team by Email (trace@ddbj.nig.ac.jp).

## JGA

TBD

## AGD

Same with JGA. Enter AGD metadata to the JGA excel "JGA_metadata.xlsx".
Specify the AGD Submission ID (e.g. ASUB000001).

## NIG SuperComputer

The singularity image is available at `/lustre9/open/shared_data/software/submission-excel2xml/` in the [NIG SuperComputer](https://www.ddbj.nig.ac.jp/sc) operated by Bioinformation and DDBJ Center, National Institute of Genetics. The SuperComputer user can readily generate XMLs from the metadata excel file and check the XMLs.

### DRA

The user can create DRA metadata XMLs and transfer corresponding data files to the DRA file server (ftp-private.ddbj.nig.ac.jp) in the SuperComputer.

Generate Submission, Experiment and Run XMLs from the excel.
```
cp /lustre9/open/shared_data/software/submission-excel2xml/excel2xml.simg ~/
cd
singularity exec excel2xml.simg excel2xml -a example -i 0001 -p PRJDB7252 example/example-0001_dra_metadata.xlsx
```

Validate the XMLs.
```
singularity exec excel2xml.simg validate_meta_dra -a example -i 0001
```

### JGA

TBD

### AGD

TBD

## 開発環境構築

```
cd submission-excel2xml
bundle install
bundle exec submission-excel2xml download_xsd
bundle exec excel2xml_dra # or excel2xml_jga, etc.
```
