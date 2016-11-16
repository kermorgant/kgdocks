FROM nginx:stable
MAINTAINER Mikael Kermorgant <mikael@kgtech.fi>
ENV REFRESHED_AT 2016-11-01

RUN apt-get update && apt-get install -y \
    geoip-database \
    libgeoip1 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html

COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /usr/local/bin/wait-for-it.sh
# RUN ln -sf /proc/1/fd/1 /var/log/nginx/access.log
# RUN ln -sf /proc/1/fd/2 /var/log/nginx/error.log

#ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
