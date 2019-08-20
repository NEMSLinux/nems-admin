FROM nemsprep:latest

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

# /tmp will be a tmpfs volume
VOLUME ["/tmp/"]

MAINTAINER Robbie Ferguson <nems@category5.tv>

ENTRYPOINT ["/usr/bin/systemctl","default","--init"]

RUN echo "" && ps -fp 1 && sleep 5

RUN /root/nems/nems-admin/nems-build.sh 21
