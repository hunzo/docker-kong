#!/bin/sh
export VERSION=latest
docker network create kong-net
docker run -d --name kong-database \
     --network=kong-net \
     --restart=always \
     -p 5432:5432 \
     -e "POSTGRES_USER=kong" \
     -e "POSTGRES_DB=kong" \
     -e "POSTGRES_HOST_AUTH_METHOD=trust" \
     postgres:9.6
sleep 5
docker run --rm \
     --network=kong-net \
     -e "KONG_DATABASE=postgres" \
     -e "KONG_PG_HOST=kong-database" \
     kong:$VERSION kong migrations bootstrap

docker run -d --name kong \
     --network=kong-net \
     --restart=always \
     -e "KONG_DATABASE=postgres" \
     -e "KONG_PG_HOST=kong-database" \
     -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
     -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
     -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
     -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
     -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
     -p 9080:8000 \
     -p 9443:8443 \
     kong:$VERSION

docker run -d --name konga-database \
     --network=kong-net \
     --restart=always \
     -e "POSTGRES_USER=kong" \
     -e "POSTGRES_DB=kong" \
     -e "POSTGRES_HOST_AUTH_METHOD=trust" \
     postgres:9.6
sleep 5
docker run --rm --network=kong-net pantsel/konga -c prepare -a postgres -u postgresql://kong@konga-database:5432/konga_db 
docker run -d -p 1337:1337 \
     --network=kong-net \
     --restart=always \
     -e "DB_ADAPTER=postgres" \
     -e "DB_HOST=konga-database" \
     -e "DB_USER=kong" \
     -e "DB_DATABASE=konga_db" \
     -e "KONGA_HOOK_TIMEOUT=120000" \
     -e "NODE_ENV=production" \
     --name konga \
     pantsel/konga
