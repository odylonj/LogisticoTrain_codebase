#!/bin/sh
set -eu

export PMA_HOST="${PMA_HOST:-sqldatabase}"
export PMA_PORT="${PMA_PORT:-3306}"
export PMA_USER="$(cat /run/secrets/sql_app_user)"
export PMA_PASSWORD="$(cat /run/secrets/sql_app_password)"

exec /docker-entrypoint.sh apache2-foreground
