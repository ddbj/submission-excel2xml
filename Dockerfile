FROM ruby:3.2
ENV RUBYOPT -EUTF-8
ENV PATH /opt/submission-excel2xml:$PATH

MAINTAINER Bioinformation and DDBJ Center
RUN export DEBIAN_FRONTEND="noninteractive" && \
    apt-get -y update && \
    apt -y install libxml2-utils && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /opt/submission-excel2xml
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.analysis.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.annotation.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.common.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.experiment.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.package.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.run.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.sample.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.study.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/dra/xsd/1-5/SRA.submission.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.analysis.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.common.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.dac.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.data.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.dataset.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.experiment.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.policy.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.sample.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.study.xsd && \
    wget https://raw.githubusercontent.com/ddbj/pub/master/docs/jga/xsd/1-2/JGA.submission.xsd

COPY excel2xml_dra.rb validate_meta_dra.rb excel2xml_jga.rb validate_meta_jga.rb ./
