FROM ubuntu:18.04
MAINTAINER Bioinformation and DDBJ Center
RUN sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.jaist.ac.jp/pub/Linux/ubuntu/%g" /etc/apt/sources.list && \
    sed -i.bak -e "s%http://security.ubuntu.com/ubuntu/%http://ftp.jaist.ac.jp/pub/Linux/ubuntu/%g" /etc/apt/sources.list
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install vim \
                       less \
                       build-essential \
                       libxml2-dev \
                       zlib1g-dev \
                       libxml2-utils \
                       ruby-full=1:2.5.1
RUN gem install mini_portile2 -v "2.4.0" && \
    gem install nokogiri -v "1.10.9" && \
    gem install rubyzip -v "2.3.0" && \
    gem install roo -v "2.8.3" && \
    gem install builder -v "3.2.4" && \
    gem install date -v "3.0.0" && \
    mkdir /opt/submission-excel2xml
COPY excel2xml.rb /usr/local/bin
COPY validate_dra_meta.rb /usr/local/bin
COPY SRA.analysis.xsd /opt/submission-excel2xml
COPY SRA.annotation.xsd /opt/submission-excel2xml
COPY SRA.common.xsd /opt/submission-excel2xml
COPY SRA.experiment.xsd /opt/submission-excel2xml
COPY SRA.package.xsd /opt/submission-excel2xml
COPY SRA.run.xsd /opt/submission-excel2xml
COPY SRA.sample.xsd /opt/submission-excel2xml
COPY SRA.study.xsd /opt/submission-excel2xml
COPY SRA.submission.xsd /opt/submission-excel2xml

RUN chmod +x /usr/local/bin/excel2xml.rb && \
    chmod +x /usr/local/bin/validate_dra_meta.rb

