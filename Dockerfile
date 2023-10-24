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
RUN bundle install
COPY *.rb Rakefile ./
RUN bundle exec rake download_xsd
