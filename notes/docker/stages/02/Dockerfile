FROM nemsprep:latest

LABEL nemsver="1.5.2"

ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive

# tmpfs volumes (see deployment instructions)
#VOLUME ["/tmp/","/var/www/html/backup/snapshot/"]
VOLUME ["/var/www/html/backup/snapshot/"]

MAINTAINER Robbie Ferguson <nems@category5.tv>

ENTRYPOINT ["/usr/bin/systemctl","default","--init"]

RUN /root/nems/nems-admin/nems-build.sh 21
