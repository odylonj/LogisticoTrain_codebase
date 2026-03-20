#!/bin/sh
set -eu

ROOT_USER="$(cat /run/secrets/mongo_root_user)"
ROOT_PASSWORD="$(cat /run/secrets/mongo_root_password)"
BASIC_AUTH_USER="$(cat /run/secrets/mongo_express_basic_auth_user)"
BASIC_AUTH_PASSWORD="$(cat /run/secrets/mongo_express_basic_auth_password)"

export ME_CONFIG_MONGODB_URL="mongodb://${ROOT_USER}:${ROOT_PASSWORD}@nosqldatabase:27017/?authSource=admin"
export ME_CONFIG_BASICAUTH_USERNAME="$BASIC_AUTH_USER"
export ME_CONFIG_BASICAUTH_PASSWORD="$BASIC_AUTH_PASSWORD"

exec /docker-entrypoint.sh
