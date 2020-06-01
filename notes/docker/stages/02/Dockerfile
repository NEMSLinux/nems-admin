FROM nemsprep:latest

LABEL nemsver="1.6"

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

# tmpfs volumes (see deployment instructions)
#VOLUME ["/tmp/","/var/www/html/backup/snapshot/"]
VOLUME ["/var/www/html/backup/snapshot/"]

MAINTAINER Robbie Ferguson <nems@category5.tv>

ENTRYPOINT ["/usr/bin/systemctl","default","--init"]

EXPOSE 80/tcp 443/tcp 2812/tcp 5666/tcp

RUN /root/nems/nems-admin/nems-build.sh 21
