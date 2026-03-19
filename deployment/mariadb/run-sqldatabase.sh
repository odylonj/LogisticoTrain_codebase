#!/bin/sh
set -eu

export MARIADB_ROOT_PASSWORD="$(cat /run/secrets/sql_root_password)"
export MARIADB_DATABASE="${SQL_DATABASE:-myrames-prod-db}"
export MARIADB_USER="$(cat /run/secrets/sql_app_user)"
export MARIADB_PASSWORD="$(cat /run/secrets/sql_app_password)"

exec docker-entrypoint.sh mariadbd \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_general_ci \
  --skip-name-resolve
