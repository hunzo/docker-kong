#!/bin/sh
export VERSION=latest

# docker stop kong | sleep 5 | docker rm kong

# update database 
docker run --rm \
     --network=kong-net \
     -e "KONG_DATABASE=postgres" \
     -e "KONG_PG_HOST=kong-database" \
     kong:$VERSION kong migrations up

docker run --rm \
     --network=kong-net \
     -e "KONG_DATABASE=postgres" \
     -e "KONG_PG_HOST=kong-database" \
     kong:$VERSION kong migrations finish

# start new kong instance
docker run -d --name kong-upgrade \
     --network=kong-net \
     --restart=always \
     -e "KONG_DATABASE=postgres" \
     -e "KONG_PG_HOST=kong-database" \
     -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
     -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
     -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
     -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
     -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
     -e "TZ=Asia/Bangkok" \
     -p 9080:8000 \
     -p 9443:8443 \
     kong:$VERSION