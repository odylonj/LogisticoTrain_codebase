#!/bin/sh
set -eu

APP_DB="${MONGO_APP_DATABASE:-history-db}"
APP_USER="$(cat /run/secrets/mongo_app_user)"
APP_PASSWORD="$(cat /run/secrets/mongo_app_password)"

mongosh --quiet \
  --authenticationDatabase admin \
  --username "$MONGO_INITDB_ROOT_USERNAME" \
  --password "$MONGO_INITDB_ROOT_PASSWORD" <<EOF
db = db.getSiblingDB("admin");
if (!db.getUser("$APP_USER")) {
  db.createUser({
    user: "$APP_USER",
    pwd: "$APP_PASSWORD",
    roles: [{ role: "readWrite", db: "$APP_DB" }]
  });
}
EOF
