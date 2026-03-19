#!/bin/sh
set -eu

ROOT_USER="$(cat /run/secrets/mongo_root_user)"
ROOT_PASSWORD="$(cat /run/secrets/mongo_root_password)"

export ME_CONFIG_MONGODB_URL="mongodb://${ROOT_USER}:${ROOT_PASSWORD}@nosqldatabase:27017/?authSource=admin"

exec /docker-entrypoint.sh
