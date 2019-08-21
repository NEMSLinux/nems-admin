FROM debian:buster

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

# /tmp will be a tmpfs volume
#VOLUME ["/tmp/"]

MAINTAINER Robbie Ferguson <nems@category5.tv>

# Setup apt
COPY files/sources.list /etc/apt/sources.list
COPY files/apt-blacklist /etc/apt/preferences
RUN apt-get update && \
    apt-get install -y apt-utils

# Install a few prerequisites
RUN apt-get update && \
    apt-get install -y ca-certificates wget ssl-cert git unzip make python3 procps

# Setup faux systemd environment
RUN apt-get remove --purge systemd && \
    wget -O /tmp/systemctl.zip https://github.com/gdraheim/docker-systemctl-replacement/archive/v1.4.3000.zip && \
    cd /tmp && \
    unzip systemctl.zip && \
    cd docker-systemctl-replacement* && \
    make && \
    mv -f ./files/docker/systemctl3.py /usr/bin/ && \
    chmod +x /usr/bin/systemctl3.py && \
    ln -s /usr/bin/systemctl3.py /usr/bin/systemctl && \
    ln -s /usr/bin/systemctl /bin/systemctl

RUN /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite

RUN wget --no-check-certificate -O /tmp/nems-prep.sh https://raw.githubusercontent.com/Cat5TV/nems-admin/master/nems-prep.sh && \
    chmod +x /tmp/nems-prep.sh && \
    /tmp/nems-prep.sh

EXPOSE 22/tcp 80/tcp 443/tcp 2812/tcp 9090/tcp

ENTRYPOINT ["/usr/bin/systemctl","default","--init"]
