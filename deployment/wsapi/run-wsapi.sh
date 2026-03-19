#!/bin/sh
set -eu

CONFIG_DIR="$(mktemp -d /tmp/wsapi-config.XXXXXX)"
CONFIG_PATH="${CONFIG_DIR}/application.properties"

cat > "$CONFIG_PATH" <<EOF
spring.application.name=RealtimeApi
server.port=${SERVER_PORT:-8080}
spring.devtools.add-properties=false
spring.devtools.restart.enabled=false
spring.devtools.livereload.enabled=false

server.servlet.session.cookie.name=logisticoRTApi
server.servlet.session.cookie.max-age=7200
server.servlet.session.cookie.secure=false
server.servlet.session.cookie.http-only=true
server.servlet.session.cookie.same-site=strict

spring.datasource.username=$(cat /run/secrets/sql_app_user)
spring.datasource.password=$(cat /run/secrets/sql_app_password)
spring.datasource.url=jdbc:mariadb://${SQL_HOST:-sqldatabase}:${SQL_PORT:-3306}/${SQL_DATABASE:-myrames-prod-db}
spring.datasource.driver-class-name=org.mariadb.jdbc.Driver
spring.jpa.database-platform=org.hibernate.dialect.MariaDBDialect
spring.jpa.hibernate.ddl-auto=validate

spring.data.mongodb.database=${MONGO_DATABASE:-history-db}
spring.data.mongodb.auto-index-creation=true
spring.data.mongodb.host=${MONGO_HOST:-nosqldatabase}
spring.data.mongodb.port=${MONGO_PORT:-27017}
spring.data.mongodb.authentication-database=${MONGO_AUTH_DB:-admin}
spring.data.mongodb.username=$(cat /run/secrets/mongo_app_user)
spring.data.mongodb.password=$(cat /run/secrets/mongo_app_password)

app.broker.host=${BROKER_HOST:-broker}
app.broker.port=${BROKER_PORT:-61613}
app.broker.login=$(cat /run/secrets/broker_user)
app.broker.password=$(cat /run/secrets/broker_password)
EOF

exec mvn \
  -Dmaven.repo.local=/root/.m2/repository \
  -Dspring-boot.run.arguments=--spring.config.location="$CONFIG_PATH" \
  spring-boot:run
