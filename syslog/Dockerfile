# FROM voxxit/base:alpine

FROM alpine:3.3
MAINTAINER Mikael Kermorgant <mikael.kermorgant@gmail.com>

RUN  apk add --no-cache rsyslog

EXPOSE 514 514/udp

VOLUME [ "/var/log", "/etc/rsyslog.d" ]

# for some reason, the apk comes built with a v5
# config file. using this one for v8:
COPY ./etc/rsyslog.conf /etc/rsyslog.conf

ENTRYPOINT [ "rsyslogd", "-n" ]
