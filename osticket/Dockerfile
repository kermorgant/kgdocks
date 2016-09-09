FROM php:5-fpm
MAINTAINER Mikael Kermorgant <mikael.kermorgant@gmail.com>

# setup workdir 
RUN mkdir /var/www/osticket
WORKDIR /var/www/osticket

# environment for osticket 
ENV OSTICKET_VERSION 1.9.14
ENV HOME /var/www/osticket

ENV REFRESHED_AT 2016-09-09

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
    && docker-php-ext-install mysql pdo pdo_mysql mysqli \
    && docker-php-ext-install soap gettext calendar zip \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap

WORKDIR /var/www

# Download & install OSTicket
RUN wget -nv -O osTicket.zip http://osticket.com/sites/default/files/download/osTicket-v${OSTICKET_VERSION}.zip && \
    unzip osTicket.zip && \
    rm osTicket.zip && \
    mv upload/* /var/www/osticket && \
    chown -R www-data:www-data /var/www/osticket/ && \
    mv /var/www/osticket/setup /var/www/osticket/setup_hidden && \
    chown -R root:root /var/www/osticket/setup_hidden && \
    chmod 700 /var/www/osticket/setup_hidden && \
    chmod 777 /var/www/osticket/include

# Download languages packs
RUN wget -nv -O osticket/include/i18n/fr.phar http://osticket.com/sites/default/files/download/lang/fr.phar && \
    wget -nv -O osticket/include/i18n/fi.phar http://osticket.com/sites/default/files/download/lang/fi.phar && \
    wget -nv -O osticket/include/i18n/sv_SE.phar http://osticket.com/sites/default/files/download/lang/sv_SE.phar && \
    wget -nv -O osticket/include/i18n/de.phar http://osticket.com/sites/default/files/download/lang/de.phar

VOLUME ["/var/www/osticket"]

ADD supervisord.conf /usr/local/etc/supervisord.conf
ADD msmtp.conf /usr/local/etc/msmtp.conf

ADD bin/install.php /usr/local/bin
ADD bin/start.sh /start.sh

EXPOSE 80
CMD ["/start.sh"]