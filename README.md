# docker config for persistent server setup

This is my setup for a docker environment hosted on a single machine (I started this in 2016 as a way to learn a bit about docker).

Features :

* docker-compose with splitted config files (base, dev, prod, admin)
* wrapper script (compose.sh) to ease the overriding of config files and avoid mistakes
* docker volumes for data persistence
* one nginx container for the web frontend
* each php app in its own container (based on php:5-fpm)
 * nginx communicate with each php-fpm container via port 9000
 * each php app resides in a docker volume, that is also shared wih the nginx container, so that non php assets can be served by nginx

## First start

* Networks and volumes are created outside of compose's project environment, so you have to create them "by hand".
* Then, take care of setting up all the required "*.env" files referenced in the docker-compose.<env>.file (env = prod | dev).
* Hmm, have to admit I haven't tested this much in a "clean state". Assumption of existing database or file may need to be fixed.

### network creation
```
sudo docker network create back
sudo docker network create front
```

### volume creation
```
sudo docker volume create --name odoo-etc
sudo docker volume create --name odoo-addons
sudo docker volume create --name odoo-var
sudo docker volume create --name pgstore
sudo docker volume create --name mariadbstore
sudo docker volume create --name openvpndata
sudo docker volume create --name xibodata
sudo docker volume create --name redminedata
sudo docker volume create --name bookeddata
```

### start in dev environment

* First, take care of assessing environment variables
 * each container has its own <service>.env file in its own folder
 * private settings are to be put in non versioned env files 
  * docker.env (see docker.priv.env-dist)
  * common.env (see common.priv.env-dist)

```
./compose.sh build nginx
./compose.sh up -d nginx
```

### start in prod environment
* Environment variables are placed in dedicated files, in /etc/docker

```
./compose.sh build nginx
./compose.sh up -d nginx
```


### backup & restore

backup of the volumes is simple 
```
./compose.sh backup
```

restore is a bit more involved. Suppose we want to restore the content of mariadbstore
```
sudo docker-compose -f docker-compose.yml -f docker-compose.$ENV.yml -f docker-compose.admin.yml run --rm backup
```
then
```
cd /
rm -Rf /volumes/mariadbstore/*
tar -xvzf /backup/vps-volumes-back.tgz volumes/mariadbstore
```


## Credits

[Xibo image](https://github.com/xibosignage/xibo-docker) by Spring Signage

[Giles Hall / vishnubob](https://github.com/vishnubob) for its wait-for-it bash script

And many others I just don't remember of
