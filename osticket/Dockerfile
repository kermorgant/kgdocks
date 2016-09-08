FROM php:5-fpm
MAINTAINER Mikael Kermorgant <mikael.kermorgant@gmail.com>

# setup workdir 
RUN mkdir /data
WORKDIR /data

# environment for osticket 
ENV OSTICKET_VERSION 1.9.12 
ENV HOME /data

ENV REFRESHED_AT 2016-06-28

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        msmtp \
        wget \
        nano \
        supervisor \
        unzip \
        mysql-client \
        libpng-dev \
        libcurl4-gnutls-dev \
        libmcrypt-dev \
        libxml2-dev \
        libicu-dev \
        libssl-dev \
        libc-client2007e-dev \
        libkrb5-dev \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install gd curl \
    && docker-php-ext-install iconv mcrypt \
    && docker-php-ext-install mysql pdo pdo_mysql\
    && docker-php-ext-install soap gettext calendar zip \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap

# Download & install OSTicket
RUN wget -nv -O osTicket.zip http://osticket.com/sites/default/files/download/osTicket-v${OSTICKET_VERSION}.zip && \
    unzip osTicket.zip && \
    rm osTicket.zip && \
    chown -R www-data:www-data /data/upload/ && \
    mv /data/upload/setup /data/upload/setup_hidden && \
    chown -R root:root /data/upload/setup_hidden && \
    chmod 700 /data/upload/setup_hidden

# Download languages packs
RUN wget -nv -O upload/include/i18n/fr.phar http://osticket.com/sites/default/files/download/lang/fr.phar && \
    wget -nv -O upload/include/i18n/ar.phar http://osticket.com/sites/default/files/download/lang/ar.phar && \
    wget -nv -O upload/include/i18n/pt_BR.phar http://osticket.com/sites/default/files/download/lang/pt_BR.phar && \
    wget -nv -O upload/include/i18n/it.phar http://osticket.com/sites/default/files/download/lang/it.phar && \
    wget -nv -O upload/include/i18n/fi.phar http://osticket.com/sites/default/files/download/lang/fi.phar && \
    wget -nv -O upload/include/i18n/sv_SE.phar http://osticket.com/sites/default/files/download/lang/sv_SE.phar && \
    wget -nv -O upload/include/i18n/es_ES.phar http://osticket.com/sites/default/files/download/lang/es_ES.phar && \
    wget -nv -O upload/include/i18n/de.phar http://osticket.com/sites/default/files/download/lang/de.phar

ADD supervisord.conf /data/supervisord.conf
ADD msmtp.conf /data/msmtp.conf
ADD bin/ /data/bin

VOLUME ["/data/upload/include/plugins","/var/log/nginx"]
EXPOSE 80
CMD ["/data/bin/start.sh"]
