#!/bin/bash

environments=(dev prod)

if [ ! -f docker.priv.env ]
then
  echo "docker.priv.env file missing. Please create one"
  exit 1
fi

eval $(cat docker.priv.env)
cmdprefix="eval $(cat docker.priv.env)"

if [[ -z $ENV || ! ${environments[*]} =~ $ENV ]]
then
  echo "ENV variable not set or has unacceptable value."
  exit 1
fi 


while getopts ":h" opt; do
  case ${opt} in
    h )
      echo "Usage:"
      echo "    ./compose.sh -h			Display this help message."
      echo "    ./compose.sh build service		Builds a service defined in the configuration"
      echo "    ./compose.sh up service		Runs a service as a daemon (the -d is automatically added)"
      echo "    ./compose.sh stop service		Stops specified service"      
      echo "    ./compose.sh openvpn		Runs the openvpn service as a daemon"
      echo "    ./compose.sh backup			Performs a backup of the volumes listed in docker-compose.admin.yml"
      echo "    ./compose.sh exec-bash service  Opens a bash shell inside a running container"
      exit 0
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))


subcommand=$1; shift  # Remove 'compose.sh' from the argument list
case "$subcommand" in
  # Parse options to the install sub command
  pull)
    service=$1; shift  # Remove 'build' from the argument list
    command="$cmdprefix sudo -E docker-compose -f ./docker-compose.yml -f docker-compose.$ENV.yml pull $service"  
    ;;
    
  build)
    service=$1; shift  # Remove 'build' from the argument list
    command="$cmdprefix sudo -E docker-compose -f ./docker-compose.yml -f docker-compose.$ENV.yml build --pull $service"
    ;;
    
  up)
    # Process package options
    while getopts ":d:" opt; do
      case ${opt} in
        d )
          service=$OPTARG
          ;;
        \? )
          echo "Invalid Option: -$OPTARG" 1>&2
          exit 1
          ;;
        : )
          echo "Invalid Option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done
    if [ -z $service ]
    then
      if [ -z $1 ]
      then
        echo "Missing option : up requires an argument (the service)"
        exit 1
      else
        service=$1; shift
      fi
    fi      
    shift $((OPTIND -1))

    command="$cmdprefix sudo -E docker-compose -f ./docker-compose.yml -f docker-compose.$ENV.yml up -d $service"
    echo $command    
    ;;
    
  stop)
    if [ ! -z $1 ]
    then
      service=$1; shift
    fi
    shift $((OPTIND -1))

    command="$cmdprefix sudo -E docker-compose -f ./docker-compose.yml -f docker-compose.$ENV.yml stop $service"
    echo $command    
    ;;    
    
  openvpn)  
    command="$cmdprefix sudo -E docker-compose -f ./docker-compose.yml -f docker-compose.$ENV.yml -f docker-compose.admin.yml up -d openvpn"
    ;;
    
  backup)
    echo "Performing backup  of docker volumes in /backup" 
    command="$cmdprefix sudo -E docker-compose -f ./docker-compose.yml -f docker-compose.$ENV.yml -f docker-compose.admin.yml run --rm backup"
    ;;
    
  exec-bash)
    if [ -z $1 ]
    then
      echo "Missing option : exec-bash requires an argument (the service)"
      exit 1
    else
      service=$1; shift
      command="$cmdprefix sudo -E docker-compose -f ./docker-compose.yml -f docker-compose.$ENV.yml exec $service /bin/bash"
      echo $command
    fi  
    ;;
    
    sslrenew)  
    command="$cmdprefix sudo -E docker-compose -f ./docker-compose.yml -f docker-compose.$ENV.yml -f docker-compose.admin.yml run --rm letsencrypt renew"
    ;;
esac

$command
