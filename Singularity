BootStrap: docker
From: ubuntu:18.04

%setup


%files
    # copying files from the host system to the container.
    excel2xml.rb /usr/local/bin
    validate_dra_meta.rb /usr/local/bin
    SRA.analysis.xsd /opt
    SRA.annotation.xsd /opt
    SRA.common.xsd /opt
    SRA.experiment.xsd /opt
    SRA.package.xsd /opt
    SRA.run.xsd /opt
    SRA.sample.xsd /opt
    SRA.study.xsd /opt
    SRA.submission.xsd /opt

%labels
    Maintainer Bioinformation and DDBJ Center
    Version    v1.0


%runscript



%post
    echo "Hello from inside the container"
    sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.jaist.ac.jp/pub/Linux/ubuntu/%g" /etc/apt/sources.list
    sed -i.bak -e "s%http://security.ubuntu.com/ubuntu/%http://ftp.jaist.ac.jp/pub/Linux/ubuntu/%g" /etc/apt/sources.list
    apt-get -y update
    apt-get -y upgrade
    apt-get -y install vim less build-essential libxml2-dev zlib1g-dev libxml2-utils \
                       ruby-full=1:2.5.1
    gem install mini_portile2 -v "2.4.0"
    gem install nokogiri -v "1.10.9"
    gem install rubyzip -v "2.3.0"
    gem install roo -v "2.8.3"
    gem install builder -v "3.2.4"
    gem install date -v "3.0.0"

    chmod +x /usr/local/bin/excel2xml.rb
    chmod +x /usr/local/bin/validate_dra_meta.rb
    mkdir /opt/submission-excel2xml
    mv /opt/SRA.*.xsd /opt/submission-excel2xml/

