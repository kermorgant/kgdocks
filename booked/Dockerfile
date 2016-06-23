FROM php:5-fpm
MAINTAINER Mikael Kermorgant <mikael.kermorgant@gmail.com>
ENV REFRESHED_AT 2016-06-20

RUN apt-get update && apt-get install -y \
    ssmtp \
    wget curl \
    anacron \
    mysql-client \
    libcurl4-gnutls-dev \
    libmcrypt-dev \
    freetype* libjpeg-dev libxpm-dev libpng-dev\
    libxml2-dev \
    libicu-dev \
    unzip \
    && docker-php-ext-configure gd  --with-freetype-dir=/usr/include/freetype2 --with-jpeg-dir=/usr/include \
    && docker-php-ext-install gd curl \
    && docker-php-ext-install iconv mcrypt \
    && docker-php-ext-install pdo pdo_mysql mysqli \
    && docker-php-ext-install mysql soap gettext calendar zip \
    && docker-php-ext-install intl mysqli

ENV BOOKED_VERSION=2.5.20

ADD wait-for-it.sh /usr/local/bin/wait-for-it.sh
ADD config.php /tmp/config.php-template

ADD http://downloads.sourceforge.net/project/phpscheduleit/Booked/2.5/booked-${BOOKED_VERSION}.zip /var/www/booked.zip
RUN mkdir -p /var/www/booked

VOLUME /var/www/booked
WORKDIR /var/www/booked

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/wait-for-it.sh

# Create a flag file which the bootstrapping process will delete
# This tells us if we're doing a new install/upgrade on run
RUN touch /INSTALL-FLAG

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm"]
