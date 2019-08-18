FROM debian:buster

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

MAINTAINER Robbie Ferguson <nems@category5.tv>

# add contrib, non-free and backports repositories
ADD sources.list /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y apt-utils

RUN apt-get update && \
    apt-get install -y systemd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*


RUN apt-get update && \
    apt-get install -y ca-certificates wget ssl-cert git

RUN /usr/sbin/make-ssl-cert generate-default-snakeoil --force-overwrite

VOLUME [ "/sys/fs/cgroup" ]

CMD ["/lib/systemd/systemd"]

RUN wget --no-check-certificate -O /tmp/nems-prep.sh https://raw.githubusercontent.com/Cat5TV/nems-admin/master/nems-prep.sh && \
    chmod +x /tmp/nems-prep.sh && \
    /tmp/nems-prep.sh

