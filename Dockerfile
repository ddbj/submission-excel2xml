FROM ruby:3.2

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libxml2-utils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/submission-excel2xml

COPY . ./
RUN bundle install && \
    bundle exec rake install && \
    bundle exec rake clobber
RUN excel2xml download_xsd
