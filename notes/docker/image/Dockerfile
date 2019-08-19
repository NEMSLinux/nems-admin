FROM debian:buster

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

MAINTAINER Robbie Ferguson <nems@category5.tv>

# Setup apt
ADD sources.list /etc/apt/sources.list
RUN apt-get update && \
    apt-get install -y apt-utils

# Install a few prerequisites
RUN apt-get update && \
    apt-get install -y ca-certificates wget ssl-cert git unzip make python3

# Setup faux systemctl environment
RUN wget -O /tmp/systemctl.zip https://github.com/gdraheim/docker-systemctl-replacement/archive/v1.4.3000.zip && \
    cd /tmp && \
    unzip systemctl.zip && \
    cd docker-systemctl-replacement* && \
    make && \
    mv ./files/docker/systemctl3.py /usr/local/bin/ && \
    chmod +x /usr/local/bin/systemctl3.py && \
    ln -s /usr/local/bin/systemctl3.py /bin/systemctl

RUN /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite

RUN wget --no-check-certificate -O /tmp/nems-prep.sh https://raw.githubusercontent.com/Cat5TV/nems-admin/master/nems-prep.sh && \
    chmod +x /tmp/nems-prep.sh && \
    /tmp/nems-prep.sh

RUN apt update && \
    /root/nems/nems-admin/nems-build.sh 21

# apache2
EXPOSE 80/tcp
EXPOSE 443/tcp
# monit
EXPOSE 2812/tcp
# cockpit
EXPOSE 9090/tcp

VOLUME /tmp/

CMD /bin/systemctl
