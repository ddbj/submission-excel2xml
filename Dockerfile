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
                       wget \
                       ruby-full=1:2.5.1
RUN gem install mini_portile2 -v "2.4.0" && \
    gem install nokogiri -v "1.10.9" && \
    gem install rubyzip -v "2.3.0" && \
    gem install roo -v "2.8.3" && \
    gem install builder -v "3.2.4" && \
    gem install date -v "3.0.0" && \
    mkdir /opt/submission-excel2xml && \
    cd /opt/submission-excel2xml && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.analysis.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.annotation.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.common.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.experiment.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.package.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.run.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.sample.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.study.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.submission.xsd

COPY excel2xml.rb /usr/local/bin
COPY validate_dra_meta.rb /usr/local/bin

RUN chmod +x /usr/local/bin/excel2xml.rb && \
    chmod +x /usr/local/bin/validate_dra_meta.rb

