#!/bin/sh
set -eu

export MONGO_INITDB_ROOT_USERNAME="$(cat /run/secrets/mongo_root_user)"
export MONGO_INITDB_ROOT_PASSWORD="$(cat /run/secrets/mongo_root_password)"
export MONGO_INITDB_DATABASE="${MONGO_APP_DATABASE:-history-db}"

exec docker-entrypoint.sh mongod --bind_ip_all
