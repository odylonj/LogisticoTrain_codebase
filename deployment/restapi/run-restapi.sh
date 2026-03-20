#!/bin/sh
set -eu

CONFIG_PATH="$(mktemp /tmp/restapi-config.XXXXXX.py)"

cat > "$CONFIG_PATH" <<EOF
SERVER_HOST = '${RESTAPI_HOST:-0.0.0.0}'
SERVER_PORT = ${RESTAPI_PORT:-5001}
DEBUG = False
ENABLE_CORS = False

SQLDB_SETTINGS = {
    "db": '${SQL_DATABASE:-myrames-prod-db}',
    "user": '$(cat /run/secrets/sql_app_user)',
    "password": '$(cat /run/secrets/sql_app_password)',
    "host": '${SQL_HOST:-sqldatabase}',
    "port": ${SQL_PORT:-3306}
}

MONGODB_SETTINGS = {
    "db": "${MONGO_DATABASE:-history-db}",
    "host": "${MONGO_HOST:-nosqldatabase}",
    "port": ${MONGO_PORT:-27017},
    "username": "$(cat /run/secrets/mongo_app_user)",
    "password": "$(cat /run/secrets/mongo_app_password)",
    "authentication_source": "${MONGO_AUTH_DB:-admin}"
}
EOF

export RESTAPI_CONFIG_PATH="$CONFIG_PATH"

exec python -u /usr/local/bin/serve_restapi.py
