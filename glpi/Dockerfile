FROM php:7-apache
MAINTAINER Mikael Kermorgant <mikael@kgtech.fi>
ENV REFRESHED_AT 2016-11-01

RUN apt-get update && apt-get install -y \
    ssmtp \
    mysql-client \
    libpng-dev \
    libjpeg-dev \
    libcurl4-gnutls-dev \
    libmcrypt-dev \
    libicu-dev \
    libxml2-dev  \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install gd curl \
    && docker-php-ext-install iconv mcrypt \
    && docker-php-ext-install pdo pdo_mysql \
    && docker-php-ext-install mysqli soap gettext calendar zip \
    && docker-php-ext-install intl

COPY entrypoint.sh /entrypoint.sh
COPY wait-for-it.sh  /usr/local/bin/wait-for-it.sh

RUN chmod +x /entrypoint.sh /usr/local/bin/wait-for-it.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["apache2-foreground"]
