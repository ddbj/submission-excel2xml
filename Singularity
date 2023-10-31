BootStrap: docker
From: ruby:3.2

%environment
    export XDG_DATA_HOME=/opt/submission-excel2xml/data

%files
    . /opt/submission-excel2xml

%labels
    Maintainer Bioinformation and DDBJ Center
    Version    v2.0

%post
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y libxml2-utils
    rm -rf /var/lib/apt/lists/*

    cd /opt/submission-excel2xml
    bundle install
    bundle exec rake install
    bundle exec rake clobber

    XDG_DATA_HOME=/opt/submission-excel2xml/data submission-excel2xml download_xsd
